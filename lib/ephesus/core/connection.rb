# frozen_string_literal: true

require 'securerandom'

require 'plumbum'

require 'ephesus/core'
require 'ephesus/core/messaging/publisher'

module Ephesus::Core
  # Class representing an external connection to the server.
  class Connection
    include Plumbum::Consumer
    prepend Plumbum::Parameters
    include Ephesus::Core::Messaging::Publisher

    # Exception raised when a matching formatter is not defined.
    class FormatNotFoundError < StandardError; end

    dependency :formats, default: {}, private: true

    # @param format [String] the configured format for the connection.
    def initialize(format:)
      @format = format
      @id     = SecureRandom.uuid_v7
    end

    # @return [Ephesus::Core::Actor] the game actor defined for the connection.
    attr_accessor :actor

    # @return [String] the configured format for the connection.
    attr_reader :format

    # @return [String] a unique identifier for the connection.
    attr_reader :id

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
    def handle_notification(_message) = nil

    private

    def format_options = {}
  end
end
