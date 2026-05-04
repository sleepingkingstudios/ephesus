# frozen_string_literal: true

require 'ephesus/core/formats/plain_text'

module Ephesus::Core::Formats::PlainText
  # Error message for passing an error from a connection to a plain text client.
  ErrorMessage =
    Ephesus::Core::Formats::ErrorMessage.define(:text) do
      # @param error [Cuprum::Error] the error to report.
      # @param format [String] the configured format for the connection.
      # @param message [String] the error message.
      # @param error_id [String] a unique identifier for the error.
      # @param details [Hash] the error details.
      # @param text [String] the text to display to the end user.
      def initialize( # rubocop:disable Metrics/ParameterLists
        error:,
        format:,
        text:,
        message:  nil,
        error_id: nil,
        details:  {}
      )
        error_id ||= SecureRandom.uuid_v7
        message  ||= error.message

        super
      end
    end
end
