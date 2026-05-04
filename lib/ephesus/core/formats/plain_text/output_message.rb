# frozen_string_literal: true

require 'ephesus/core/formats/plain_text'

module Ephesus::Core::Formats::PlainText
  # Output event generated for a client using the Plain Text format.
  OutputMessage =
    Ephesus::Core::Formats::OutputMessage.define(:text) do
      def initialize(**)
        format ||= Ephesus::Core::Formats::PlainText.type

        super(format:, text:, **)
      end
    end
end
