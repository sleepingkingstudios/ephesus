# frozen_string_literal: true

require 'ephesus/core'
require 'ephesus/core/messaging/publisher'
require 'ephesus/core/messaging/subscriber'

module Ephesus::Core
  # Object representing an active participant in a scene.
  #
  # Actor subclasses may represent external users (through a Connection) or
  # autonomous agents.
  class Actor
    include Ephesus::Core::Messaging::Publisher
    include Ephesus::Core::Messaging::Subscriber

    def initialize
      @id = SecureRandom.uuid_v7
    end

    # @return [Ephesus::Core::Scene] the current scene for the actor.
    attr_accessor :current_scene

    # @return [String] a unique identifier for the actor.
    attr_reader :id

    # @return [Hash] a JSON-compatible representating of the actor.
    def as_json = { 'id' => id }

    # Handles update connection messages from a Scene.
    #
    # By default, republishes the message to any subscribers.
    #
    # @param message [Ephesus::Core::Message] the received message.
    #
    # @return [void]
    def handle_connection_update(message)
      publish(message, channel: :connection_updates)

      nil
    end

    # Handles notification messages from a Scene.
    #
    # By default, republishes the notification to any subscribers.
    #
    # @param notification [Ephesus::Core::Message] the received notification.
    #
    # @return [void]
    def handle_notification(notification)
      publish(notification, channel: :notifications)

      nil
    end

    # @return [String] a human-readable representation of the actor.
    def inspect
      tools
        .object_tools
        .format_inspect(self, address: false, properties: properties_to_inspect)
    end

    private

    def properties_to_inspect = %i[id current_scene]

    def tools = @tools ||= SleepingKingStudios::Tools::Toolbelt.instance
  end
end
