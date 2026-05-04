# frozen_string_literal: true

require 'cuprum/command'

require 'ephesus/core/formats/commands'
require 'ephesus/core/formats/error_message'
require 'ephesus/core/messages/error_notification'

module Ephesus::Core::Formats::Commands
  # Converts an output notification to an output event for the current format.
  class FormatOutput < Cuprum::Command
    # @param options [Hash] additional options for parsing notifications.
    def initialize(**options)
      super()

      @options = options
    end

    # @!method call(notification)
    #   Converts the notification to a formatted output event.
    #
    #   @param notification [Ephesus::Core::Messages::Notification] the
    #     notification to process.
    #
    #   @return [Cuprum::Result<Ephesus::Core::Message>] the formatted event.
    #
    #   @return
    #     [Cuprum::Result<Ephesus::Core::Formats::Errors::UnhandledNotification]
    #     if the formatter is unable to process the notification.

    # @return [Hash] additional options for parsing notifications.
    attr_reader :options

    def format = options.fetch(:format, Ephesus::Core::Formats::DEFAULT_FORMAT)

    private

    def format_error_notification(notification)
      Ephesus::Core::Formats::ErrorMessage.new(
        error:    notification.error,
        error_id: notification.error_id,
        details:  notification.details,
        format:,
        message:  notification.message
      )
    end

    def format_output(notification)
      failure(unhandled_notification_error(notification))
    end

    def process(notification)
      if notification.is_a?(Ephesus::Core::Messages::ErrorNotification)
        return format_error_notification(notification)
      end

      format_output(notification)
    end

    def unhandled_notification_error(notification)
      Ephesus::Core::Formats::Errors::UnhandledNotification.new(notification:)
    end
  end
end
