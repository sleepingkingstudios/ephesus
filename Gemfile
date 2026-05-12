# frozen_string_literal: true

source 'https://rubygems.org'

gemspec

ruby '4.0.4'

gem 'plumbum',
  git: 'https://github.com/sleepingkingstudios/plumbum'

group :development, :test do
  gem 'byebug', '~> 12.0'
  gem 'irb', '~> 1.16'
  gem 'readline'

  gem 'rspec', '~> 3.13'
  gem 'rspec-sleeping_king_studios', '~> 2.8', '>= 2.8.3'

  gem 'rubocop',       '~> 1.82'
  gem 'rubocop-rspec', '~> 3.8'

  gem 'simplecov', '~> 0.22'

  gem 'cuprum-cli', git: 'https://github.com/sleepingkingstudios/cuprum-cli'
  gem 'thor', '~> 1.5'
end
