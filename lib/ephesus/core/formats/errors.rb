# frozen_string_literal: true

require 'ephesus/core/formats'
require 'ephesus/core/message'
require 'ephesus/core/scene'

module Ephesus::Core::Formats
  # Namespace for errors returned by failing format implementations.
  module Errors
    autoload :InputError,     'ephesus/core/formats/errors/input_error'
    autoload :OutputError,    'ephesus/core/formats/errors/output_error'
    autoload :UnhandledEvent, 'ephesus/core/formats/errors/unhandled_event'
  end
end
