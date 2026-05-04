# frozen_string_literal: true

require 'ephesus/core/formats/plain_text'

module Ephesus::Core::Formats::PlainText
  # Output event generated for a client using the Plain Text format.
  OutputMessage =
    Ephesus::Core::Formats::OutputMessage.define(:text) do
      # @param format [String] the configured format for the connection.
      # @param text [String] the text to display to the end user.
      def initialize(**)
        format ||= Ephesus::Core::Formats::PlainText.type

        super(format:, text:, **)
      end
    end
end
