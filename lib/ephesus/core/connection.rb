# frozen_string_literal: true

require 'securerandom'

require 'plumbum'

require 'ephesus/core'
require 'ephesus/core/messages/error_notification'
require 'ephesus/core/messaging/publisher'

module Ephesus::Core
  # Class representing an external connection to the server.
  class Connection
    include Plumbum::Consumer
    prepend Plumbum::Parameters
    include Ephesus::Core::Messaging::Publisher
    include Ephesus::Core::Messaging::Subscriber

    # Exception raised when unable to format an error notification.
    class FormatErrorNotificationError < StandardError; end

    # Exception raised when a matching formatter is not defined.
    class FormatNotFoundError < StandardError; end

    dependency :formats, default: {}, private: true

    # @param format [String] the configured format for the connection.
    def initialize(format:)
      @format = format
      @id     = SecureRandom.uuid_v7
    end

    # @return [Ephesus::Core::Actor] the game actor defined for the connection.
    attr_reader :actor

    # @return [String] the configured format for the connection.
    attr_reader :format

    # @return [String] a unique identifier for the connection.
    attr_reader :id

    # Sets the actor for the connection and subscribes to notifications.
    #
    # @param actor [Ephesus::Core::Actor] the actor to set.
    #
    # @return [Ephesus::Core::Actor] the set actor.
    def actor=(value)
      tools.assertions.validate_instance_of(
        value,
        as:       'actor',
        expected: Ephesus::Core::Actor
      )

      unsubscribe(actor) if actor

      @actor = value

      subscribe_to_actor
    end

    # Finds and returns a configured formatter for the connection.
    #
    # @return [Ephesus::Core::Formats::Formatter] the configured formatter.
    #
    # @raise [FormatNotFoundError] if there is not formatter matching the
    #   configured format.
    def formatter
      @formatter ||=
        formats
        .fetch(format) do
          error_message = "Formatter not found with format #{format.inspect}"

          raise FormatNotFoundError, error_message
        end
        .new(**format_options)
    end

    # Handles input events received from the server.
    #
    # @param message [Ephesus::Core::Message] the received input message.
    #
    # return [void]
    def handle_input(message)
      message = message.with(connection: self)

      publish(message, channel: :events)
    end

    # Handles notifications received from the actor.
    #
    # @param message [Ephesus::Core::Messages::Notification] the received
    #   notification.
    #
    # @return [void]
    def handle_notification(notification)
      result = formatter.format_output(notification:)

      # First, we try and format the error itself.
      if result.failure?
        result = format_error_notification(error: result.error, notification:)
      end

      # If that still fails, raise an exception - formatters should always be
      # able to format an error notification.
      if result.failure?
        raise FormatErrorNotificationError, result.error.message
      end

      publish(result.value, channel: :output)
    end

    private

    def format_error_notification(error:, notification:) # rubocop:disable Metrics/MethodLength
      details = error&.then do |err|
        { 'type' => err.type, **err.as_json['data'] }
      end

      notification = Ephesus::Core::Messages::ErrorNotification.new(
        current_actor:  notification.current_actor,
        original_actor: notification.original_actor,
        context:        notification.context,
        error_id:       SecureRandom.uuid_v7,
        message:        error&.message || 'An unknown error occurred',
        details:        details || {}
      )

      formatter.format_output(notification:)
    end

    def format_options = {}

    def subscribe_to_actor
      subscribe(
        actor,
        channel:     :notifications,
        method_name: :handle_notification
      )
    end

    def tools = @tools ||= SleepingKingStudios::Tools::Toolbelt.instance
  end
end
