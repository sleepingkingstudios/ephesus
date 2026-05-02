# frozen_string_literal: true

require 'ephesus/core/formats'

module Ephesus::Core::Formats
  # Format for plain text input and output with user clients.
  module PlainText
    include Ephesus::Core::Messages::Typing

    autoload :InputEvent, 'ephesus/core/formats/input_event'
  end
end
