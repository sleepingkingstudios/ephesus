# frozen_string_literal: true

require 'ephesus/core/formats'

module Ephesus::Core::Formats
  # Format for plain text input and output with user clients.
  module PlainText
    include Ephesus::Core::Messages::Typing

    autoload :InputMessage,  'ephesus/core/formats/input_message'
    autoload :OutputMessage, 'ephesus/core/formats/output_message'
  end
end
