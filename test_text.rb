# frozen_string_literal: true

require 'cuprum'
require 'yaml'

class ResolveTemplate < Cuprum::Command
  DATA_PATH_TEMPLATE = /\A\w+(\.\w+)+\z/

  WILDCARDS_PATTERN = /%<(\w+)>/

  UNRESOLVED = Object.new.freeze
  private_constant :UNRESOLVED

  class MissingTemplate < Cuprum::Error
    def initialize(template:)
      @template = template

      super(message: default_message, template:)
    end

    attr_reader :template

    private

    def default_message
      "Missing template #{template.inspect}"
    end
  end

  class MissingWildcard < Cuprum::Error
    def initialize(template:, wildcard:)
      @template = template
      @wildcard = wildcard

      super(message: default_message, template:, wildcard:)
    end

    attr_reader :template

    attr_reader :wildcard

    private

    def default_message
      "Missing wildcard #{wildcard.inspect} in template #{template.inspect}"
    end
  end

  class RecursiveTemplate < Cuprum::Error
    def initialize(stack:, template:)
      @stack    = stack
      @template = template

      super(message: default_message, stack:, template:)
    end

    attr_reader :stack

    attr_reader :template

    private

    def default_message
      message =
        "Unable to resolve template #{template.inspect} due to self-reference:"

      "#{message}\n#{stack.map { |str| "\n  #{str}"}.join}"
    end
  end

  def initialize(data) = @data = data

  attr_reader :data

  private

  def apply_wildcards(cache:, stack:, template:, wildcards:)
    return template unless WILDCARDS_PATTERN.match?(template)

    template.gsub(WILDCARDS_PATTERN) do |raw_match|
      match = raw_match[2...-1]
      value = wildcards.fetch(match) do
        step { failure(missing_wildcard_error(template:, wildcard: match)) }
      end

      resolve_template(cache:, stack:, template: value, wildcards:)
    end
  end

  def generate_cache_key(template:, wildcards:)
    expected = template.scan(WILDCARDS_PATTERN)

    return template if expected.empty?

    matching =
      expected
      .map { |match| "#{match.first}=#{wildcards[match.first]}" }
      .join(',')

    "#{template}:#{matching}"
  end

  def has_wildcards?(value) = WILDCARDS_PATTERN.match?(value)

  def is_data_path?(value) = DATA_PATH_TEMPLATE.match?(value)

  def load_template(cache:, stack:, template:, wildcards:)
    path  = template.split('.')
    value = data.dig(*path)

    case value
    when String
      [value, wildcards]
    when Hash
      resolve_hash(value, cache:, stack:, wildcards:) do
        step { failure(missing_template_error(template: "#{template}.template")) }
      end
    else
      step { failure(missing_template_error(template:)) }
    end
  end

  def missing_template_error(**) = MissingTemplate.new(**)

  def missing_wildcard_error(**) = MissingWildcard.new(**)

  def process(template, **wildcards)
    cache = {}
    stack = []

    resolve_template(cache:, stack:, template:, wildcards:)
  end

  def recursive_template_error(**) = RecursiveTemplate.new(**)

  def resolve_hash(value, cache:, stack:, wildcards:, &)
    template  = value.fetch('template', &)
    wildcards = value.except('template').merge(wildcards)

    resolve_template(cache:, stack:, template:, wildcards:)
  end

  def resolve_template(cache:, stack:, template:, wildcards:)
    cache_key = generate_cache_key(template:, wildcards:)

    stack << cache_key

    if cache[cache_key] == UNRESOLVED
      step { failure(recursive_template_error(template:, stack:)) }
    elsif cache.key?(cache_key)
      return cache[cache_key]
    else
      cache[cache_key] = UNRESOLVED
    end

    template = apply_wildcards(cache:, stack:, template:, wildcards:)

    unless is_data_path?(template)
      stack.pop

      return cache[cache_key] = template
    end

    template, wildcards = load_template(cache:, stack:, template:, wildcards:)

    template = apply_wildcards(cache:, stack:, template:, wildcards:)

    unless is_data_path?(template)
      stack.pop

      return cache[cache_key] = template
    end

    resolve_template(cache:, stack:, template:, wildcards:)
  end
end

def assert_equal(actual, expected)
  return if actual == expected

  raise "expected #{expected.inspect}, got #{actual.inspect}"
end

def assert_class(actual, expected)
  return if actual.is_a?(expected)

  raise "expected an instance of #{expected.inspect}, got #{actual.inspect}"
end

raw = <<~YAML
test:
  cycle:
    one: 'test.cycle.two'
    two: 'test.cycle.three'
    three: 'test.cycle.one'
  empty_hash: {}
  greek_letters:
    gamma: 'Γ'
  hash_with_path_template:
    template: 'test.messages.%<valid>'
  hash_with_self_wildcard:
    reference: 'test.hash_with_self_wildcard'
    template: 'See %<reference>'
  hash_with_text_template:
    template: 'This is output from a Hash template.'
  hash_with_wildcards:
    beta: 'Β'
    gamma: 'test.greek_letters.gamma'
    template: 'This text has %<alpha>, %<beta>, and %<gamma> wildcards.'
  messages:
    invalid: 'Something went wrong.'
    valid: 'Something went right.'
  plain_text: 'This is a plain text output.'
  path_with_redirect: 'test.redirected_text'
  path_with_self_reference: 'test.path_with_self_reference'
  path_with_wildcards: 'test.messages.%<valid>'
  redirected_text: 'This text was redirected.'
  text_with_wildcards: 'This text has %<alpha> and %<beta> wildcards.'
YAML
data    = YAML.safe_load(raw)
command = ResolveTemplate.new(data)

#===============================================================================
# RAW TEXT INPUTS
#===============================================================================

# With a raw text input.
result = command.call('This is a raw text output.')
assert_equal(result.value, 'This is a raw text output.')

# With a raw text input with missing wildcards.
result = command.call('This is a raw text output with %<alpha> and %<beta> wildcards.')
assert_class(result.error, ResolveTemplate::MissingWildcard)
assert_equal(
  result.error.message,
  'Missing wildcard "alpha" in template "This is a raw text output with %<alpha> and %<beta> wildcards."'
)

# With a raw text input with valid wildcards.
result = command.call('This is a raw text output with %<alpha> and %<beta> wildcards.', 'alpha' => 'α', 'beta' => 'β')
assert_equal(result.value, 'This is a raw text output with α and β wildcards.')

#===============================================================================
# PATH INPUTS
#===============================================================================

# With an invalid path.
result = command.call('test.missing_path')
assert_class(result.error, ResolveTemplate::MissingTemplate)
assert_equal(
  result.error.message,
  'Missing template "test.missing_path"'
)

#-------------------------------------------------------------------------------
# PATHS WITH STRING TEMPLATES
#-------------------------------------------------------------------------------

# With a path with plain text output.
result = command.call('test.plain_text')
assert_equal(result.value, 'This is a plain text output.')

# With a path with output with missing wildcards.
result = command.call('test.text_with_wildcards')
assert_class(result.error, ResolveTemplate::MissingWildcard)
assert_equal(
  result.error.message,
  'Missing wildcard "alpha" in template "This text has %<alpha> and %<beta> wildcards."'
)

# With a plain text output.
result = command.call('test.text_with_wildcards', 'alpha' => 'α', 'beta' => 'β')
assert_equal(result.value, 'This text has α and β wildcards.')

# With a path template with a redirect.
result = command.call('test.path_with_redirect')
assert_equal(result.value, 'This text was redirected.')

# With a path template with wildcards.
result = command.call('test.path_with_wildcards', 'valid' => 'invalid')
assert_equal(result.value, 'Something went wrong.')

#-------------------------------------------------------------------------------
# PATHS WITH HASH TEMPLATES
#-------------------------------------------------------------------------------

# With a path to hash with missing template.
result = command.call('test.empty_hash')
assert_class(result.error, ResolveTemplate::MissingTemplate)
assert_equal(
  result.error.message,
  'Missing template "test.empty_hash.template"'
)

# With a path to hash with text template.
result = command.call('test.hash_with_text_template')
assert_equal(result.value, 'This is output from a Hash template.')

# With a path to hash with path template.
result = command.call('test.hash_with_path_template', 'valid' => 'valid')
assert_equal(result.value, 'Something went right.')

# With a path to hash with wildcards.
result = command.call('test.hash_with_wildcards', 'alpha' => 'α', 'beta' => 'β')
assert_equal(result.value, 'This text has α, β, and Γ wildcards.')

#===============================================================================
# RECURSION HANDLING
#===============================================================================

# With a path referring to itself.
result = command.call('test.path_with_self_reference')
expected = <<~MESSAGE.strip
Unable to resolve template "test.path_with_self_reference" due to self-reference:

  test.path_with_self_reference
  test.path_with_self_reference
MESSAGE
assert_class(result.error, ResolveTemplate::RecursiveTemplate)
assert_equal(result.error.message, expected)

# With a path with a recursive wildcard.
result = command.call('test.hash_with_self_wildcard')
expected = <<~MESSAGE.strip
Unable to resolve template "test.hash_with_self_wildcard" due to self-reference:

  test.hash_with_self_wildcard
  See %<reference>:reference=test.hash_with_self_wildcard
  test.hash_with_self_wildcard
MESSAGE
assert_class(result.error, ResolveTemplate::RecursiveTemplate)
assert_equal(result.error.message, expected)

# With a path with cyclical reference.
result = command.call('test.cycle.one')
expected = <<~MESSAGE.strip
Unable to resolve template "test.cycle.one" due to self-reference:

  test.cycle.one
  test.cycle.two
  test.cycle.three
  test.cycle.one
MESSAGE
assert_class(result.error, ResolveTemplate::RecursiveTemplate)
assert_equal(result.error.message, expected)

data    = YAML.safe_load(File.read('exploration.yml'))
command = ResolveTemplate.new(data)
result  = command.call(
  'notifications.battle.commands.use_technique',
  'monster' => 'dragon',
  'technique' => 'dragon_rage'
)

puts 'OK'
