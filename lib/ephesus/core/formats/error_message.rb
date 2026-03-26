# frozen_string_literal: true

require 'securerandom'

require 'ephesus/core/formats'
require 'ephesus/core/formats/output_message'

module Ephesus::Core::Formats
  # Abstract message for passing an error from a connection to a client.
  ErrorMessage =
    Ephesus::Core::Formats::OutputMessage
    .define(:error_id, :message, :details) do
      # @param format [String] the configured format for the connection.
      # @param message [String] the error message.
      # @param error_id [String] a unique identifier for the error.
      # @param details [Hash] the error details
      def initialize(format:, message:, error_id: nil, details: {})
        error_id ||= SecureRandom.uuid_v7

        super
      end
    end
end
