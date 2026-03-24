# frozen_string_literal: true

require_relative 'lib/ephesus/version'

Gem::Specification.new do |gem|
  gem.name        = 'ephesus'
  gem.version     = Ephesus::VERSION
  gem.authors     = ['Rob "Merlin" Smith']
  gem.email       = ['sleepingkingstudios@gmail.com']

  gem.summary     = 'An engine and toolkit for developing text games in Ruby.'
  gem.description = <<~DESCRIPTION.gsub(/\s+/, ' ').strip
    An engine and toolkit for developing text games in Ruby.
  DESCRIPTION
  gem.homepage    = 'http://sleepingkingstudios.com'
  gem.license     = 'MIT'
  gem.metadata    = {
    'bug_tracker_uri'       => 'https://github.com/sleepingkingstudios/ephesus/issues',
    'changelog_uri'         => 'https://github.com/sleepingkingstudios/ephesus/CHANGELOG.md',
    'homepage_uri'          => gem.homepage,
    'source_code_uri'       => 'https://github.com/sleepingkingstudios/ephesus',
    'rubygems_mfa_required' => 'true'
  }
  gem.required_ruby_version = ['>= 4.0', '< 5']

  gem.require_paths = ['lib']
  gem.files         = Dir[
    'lib/**/*.rb',
    'LICENSE',
    '*.md'
  ]

  gem.add_dependency 'cuprum', '~> 1.3', '>= 1.3.1'

  gem.add_dependency 'observer', '< 1.0'

  gem.add_dependency 'plumbum', '~> 0.1.0.alpha'
end
