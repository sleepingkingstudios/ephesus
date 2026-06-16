# frozen_string_literal: true

require 'ephesus/core/formats/errors/output_error'
require 'ephesus/core/formats/plain_text/errors'

module Ephesus::Core::Formats::PlainText::Errors
  # Error returned when a template is not found for an outfit notification.
  class TemplateNotFound < Ephesus::Core::Formats::Errors::OutputError
    # Short string used to identify the type of error.
    TYPE = 'ephesus.core.formats.plain_text.errors.template_not_found'

    # @param details [String] additional details for the error.
    # @param expected_key [String] the expected key for the requested template.
    #   Defaults to the type of the notification.
    # @param notification [Ephesus::Core::Message] the received output
    #   notification.
    def initialize(notification:, details: nil, expected_key: nil)
      @details      = details
      @expected_key = expected_key || notification.type
      message       = default_message_for(details:, expected_key: @expected_key)

      super(details:, expected_key:, message:, notification:)
    end

    # @return [String] additional details for the error.
    attr_reader :details

    # @return [String] the expected key for the requested template.
    attr_reader :expected_key

    private

    def as_json_data
      super
        .merge({ 'details' => details, 'expected_key' => expected_key }.compact)
    end

    def default_message_for(details:, expected_key:)
      message = "template not found for message #{expected_key.inspect}"

      return message unless details

      "#{message} - #{details}"
    end
  end
end
