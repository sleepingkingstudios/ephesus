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

    # @return [String] a unique identifier for the actor.
    attr_reader :id

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
  end
end
