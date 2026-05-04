# frozen_string_literal: true

require 'ephesus/core'

module Ephesus::Core
  # Namespace for implementing IO formats for interacting with Ephesus apps.
  module Formats
    autoload :Commands,      'ephesus/core/formats/commands'
    autoload :ErrorMessage,  'ephesus/core/formats/error_message'
    autoload :Errors,        'ephesus/core/formats/errors'
    autoload :Formatter,     'ephesus/core/formats/formatter'
    autoload :InputMessage,  'ephesus/core/formats/input_message'
    autoload :OutputMessage, 'ephesus/core/formats/output_message'

    autoload :PlainText,     'ephesus/core/formats/plain_text'

    # Default format to use when a format is required but not applicable.
    DEFAULT_FORMAT = 'ephesus.core.formats.generic'
  end
end
