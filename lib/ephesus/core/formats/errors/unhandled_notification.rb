# frozen_string_literal: true

require 'ephesus/core/formats/errors'
require 'ephesus/core/formats/errors/output_error'

module Ephesus::Core::Formats::Errors
  # Error returned when a notification is not handled by the formatter.
  class UnhandledNotification < Ephesus::Core::Formats::Errors::OutputError
    # Short string used to identify the type of error.
    TYPE = 'ephesus.core.formats.errors.unhandled_notification'

    # @param notification [Ephesus::Core::Message] the received output
    #   notification.
    def initialize(notification:)
      @notification = notification

      super(notification:, message: default_message)
    end

    private

    def default_message
      message    = "Unhandled notification #{notification.type.inspect}"
      properties =
        notification
        .to_h
        .except(:current_actor, :original_actor, :context)
        .map { |key, value| "#{key}: #{value.inspect}" }

      return message if properties.empty?

      "#{message} with properties #{properties.join ', '}"
    end
  end
end
