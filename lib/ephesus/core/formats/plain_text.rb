# frozen_string_literal: true

require 'ephesus/core/formats'

module Ephesus::Core::Formats
  # Format for plain text input and output with user clients.
  module PlainText
    include Ephesus::Core::Messages::Typing

    autoload :ErrorMessage,  'ephesus/core/formats/plain_text/error_message'
    autoload :InputMessage,  'ephesus/core/formats/plain_text/input_message'
    autoload :OutputMessage, 'ephesus/core/formats/plain_text/output_message'
  end
end
