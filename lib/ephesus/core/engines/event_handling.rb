# frozen_string_literal: true

require 'ephesus/core/engines'
require 'ephesus/core/engines/errors/actor_not_assigned_scene'

module Ephesus::Core::Engines
  # Functionality for handling input events from connections.
  module EventHandling
    # Handles an input event published by a connection.
    #
    # @param event [Ephesus::Core::Message, #connection] the event to handle.
    #
    # @return [void]
    def handle_event(event) # rubocop:disable Metrics/MethodLength
      connection = event.connection
      actor      = connection.actor

      return notify_missing_actor(connection:) if actor.nil?

      scene = actor.current_scene

      return notify_actor_not_assigned_scene(actor:, connection:) if scene.nil?

      result = connection.format_input(event:, scene:)

      if result.failure?
        return notify_format_error(actor:, connection:, error: result.error)
      end

      enqueue_event(event: result.value, scene:)

      nil
    end

    private

    def enqueue_event(event:, scene:) = scene.enqueue_event(event)

    def notify_actor_not_assigned_scene(actor:, connection:)
      error   =
        Ephesus::Core::Engines::Errors::ActorNotAssignedScene.new(actor:)
      message =
        Ephesus::Core::Messages::ErrorNotification
        .new(error:, original_actor: actor)

      connection.handle_notification(message)

      nil
    end

    def notify_format_error(actor:, connection:, error:)
      message =
        Ephesus::Core::Messages::ErrorNotification
        .new(error:, original_actor: actor)

      connection.handle_notification(message)

      nil
    end

    def notify_missing_actor(connection:)
      error   =
        Ephesus::Core::Engines::Errors::MissingActor.new
      message =
        Ephesus::Core::Messages::ErrorNotification
        .new(error:, original_actor: nil)

      connection.handle_notification(message)

      nil
    end
  end
end
