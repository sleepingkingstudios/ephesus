# frozen_string_literal: true

require 'ephesus/core'

module Ephesus::Core
  # Namespace for implementing IO formats for interacting with Ephesus apps.
  module Formats
    autoload :Commands, 'ephesus/core/formats/commands'
    autoload :Errors,   'ephesus/core/formats/errors'
  end
end
