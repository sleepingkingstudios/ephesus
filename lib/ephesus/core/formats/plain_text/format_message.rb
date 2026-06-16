# frozen_string_literal: true

require 'cuprum'

require 'ephesus/core/formats/plain_text'
require 'ephesus/core/formats/plain_text/errors/template_not_found'

module Ephesus::Core::Formats::PlainText
  # Command for generating text output messages from notification events.
  class FormatMessage < Cuprum::Command # rubocop:disable Metrics/ClassLength
    PATH_PATTERN = /\A\w+(\.\w+)+\z/
    private_constant :PATH_PATTERN

    # @param registry [SleepingKingStudios::Tools::Messages::Registry] the
    #   registry used to define message templates. Defaults to the global
    #   messages registry.
    # @param scope [String, Symbol, Proc] the scope used to resolve message
    #   templates from the registry. If the scope is a string or symbol, the
    #   value is prepended to the message key before resolving the template. If
    #   the scope is a Proc, the value is called with the message key and the
    #   returned value is used to resolve the template.
    def initialize(registry: nil, scope: nil)
      super()

      @registry =
        registry || SleepingKingStudios::Tools::Messages::Registry.global
      @scope    = normalize_scope(scope)
    end

    # @return [SleepingKingStudios::Tools::Messages::Registry] the registry used
    #   to define message templates.
    attr_reader :registry

    # @return [String, Symbol, Proc] the scope used to resolve message templates
    #   from the registry.
    attr_reader :scope

    private

    def actor_is_agent?(notification) = notification.original_actor.agent?

    def actor_is_user?(notification) = notification.original_actor.user?

    def apply_scope(message_key)
      return message_key unless scope

      return scope.call(message_key) if scope.is_a?(Proc)

      "#{scope}.#{message_key}"
    end

    def find_strategy(message_key:, notification:)
      strategy = registry.get(message_key)

      return strategy if strategy

      error = template_not_found_error(
        details:      'no strategy matches requested key',
        expected_key: message_key,
        notification:
      )
      failure(error)
    end

    def find_template(strategy, message_key:, notification:)
      template = strategy.get(message_key)

      return template unless template.nil?

      error = template_not_found_error(
        details:      'template not defined',
        expected_key: message_key,
        notification:
      )
      failure(error)
    end

    def generate_hash_template(template:, wildcards:, **)
      template.except('template').each do |key, value|
        key = key.to_sym

        next if name?(wildcards[key])

        wildcards[key] =
          step { generate_wildcard(key:, value:, wildcards:, **) }
      end

      template = template['template']

      resolve_string_template(template:, wildcards:, **)
    end

    def generate_wildcard(key:, notification:, value:, wildcards:) # rubocop:disable Metrics/MethodLength
      value = format(value, wildcards) if value.include?('%<')

      if value.match?(PATH_PATTERN)
        message_key = value

        strategy = step { find_strategy(message_key:, notification:) }
        value    = step { find_template(strategy, message_key:, notification:) }
      end

      value = format(value, wildcards) if value.include?('%<')

      value
    rescue KeyError => exception
      details =
        "missing parameter #{exception.key.inspect} in template parameter " \
        "#{key.inspect}"

      failure(invalid_template_error(details:, notification:))
    end

    def invalid_template_error(**)
      Ephesus::Core::Formats::PlainText::Errors::InvalidTemplate.new(**)
    end

    def name?(value)
      return false unless value.is_a?(String) || value.is_a?(Symbol)

      !value.empty?
    end

    def normalize_scope(scope)
      return unless scope

      return scope if scope.is_a?(Proc)

      scope.to_s.sub(/\.\z/, '')
    end

    def process(notification)
      message_key = apply_scope(notification.type)
      strategy    = step { find_strategy(message_key:, notification:) }
      template    =
        step { find_template(strategy, message_key:, notification:) }

      resolve_template(notification:, template:)
    end

    def resolve_hash_template(notification:, template:, wildcards:) # rubocop:disable Metrics/MethodLength
      template = resolve_user_template(notification:, template:)

      resolved =
        if template == false
          false
        elsif template.is_a?(Hash) && template.key?('template')
          generate_hash_template(notification:, template:, wildcards:)
        elsif template.is_a?(String)
          resolve_string_template(notification:, template:, wildcards:)
        end

      return resolved unless resolved.nil?

      details = 'hash is missing key "template"'

      failure(invalid_template_error(details:, notification:))
    end

    def resolve_string_template(notification:, template:, wildcards:)
      format(template, wildcards)
    rescue KeyError => exception
      details = "missing parameter #{exception.key.inspect}"

      failure(invalid_template_error(details:, notification:))
    end

    def resolve_template(notification:, template:)
      wildcards = wildcards_for(notification)

      if template.is_a?(Hash)
        return resolve_hash_template(notification:, template:, wildcards:)
      end

      if template.is_a?(String)
        return resolve_string_template(notification:, template:, wildcards:)
      end

      details = 'template is not a Hash or a String'

      failure(invalid_template_error(details:, notification:))
    end

    def resolve_user_template(notification:, template:) # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      return template if template.key?('template')

      if template.key?('self') && same_actor?(notification)
        template['self']
      elsif template.key?('agent') && actor_is_agent?(notification)
        template['agent']
      elsif template.key?('user') && actor_is_user?(notification)
        template['user']
      elsif template.key?('other')
        template['other']
      end
    end

    def same_actor?(notification)
      notification.original_actor == notification.current_actor
    end

    def template_not_found_error(**)
      Ephesus::Core::Formats::PlainText::Errors::TemplateNotFound.new(**)
    end

    def wildcards_for(notification)
      notification
        .to_h
        .except(:current_actor, :original_actor, :context)
        .transform_keys(&:to_sym)
    end
  end
end
