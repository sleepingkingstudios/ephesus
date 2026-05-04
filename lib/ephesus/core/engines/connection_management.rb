# frozen_string_literal: true

require 'ephesus/core/actor'
require 'ephesus/core/engines'

module Ephesus::Core::Engines
  # Methods for managing actors and connections for engines.
  module ConnectionManagement
    include Ephesus::Core::Messaging::Subscriber

    # Exception raised when unable to add a connection.
    class ConnectionError < StandardError; end

    def initialize
      super

      @actors      = {}
      @connections = {}
    end

    # Adds the connection to the engine.
    #
    # This method automatically generates an Actor for the connection using
    # Engine#build_actor.
    #
    # @param [Ephesus::Core::Connection] the connection to add.
    #
    # @return [void]
    def add_connection(connection) # rubocop:disable Metrics/MethodLength
      if connection.actor
        message =
          "unable to add connection #{connection.inspect} - connection " \
          'already has an actor'

        raise ConnectionError, message
      end

      @connections[connection.id] = connection

      connection.actor = build_actor(connection)

      subscribe(
        connection,
        channel:     :events,
        method_name: :handle_event
      )

      default_scene
        &.then { |scene| add_actor_to_scene(actor: connection.actor, scene:) }

      nil
    end

    # Adds the actor to the specified scene.
    #
    # Enqueues a ConnectActor event for the scene. If the actor already belongs
    # to a scene, removes the actor from that scene and enqueues a
    # DisconnectActor event for the previous scene.
    #
    # @param actor [Ephesus::Core::Actor] the actor to add to the scene.
    # @param scene [Ephesus::Core::Scene] the scene to which the actor is added.
    #
    # @return [void]
    def add_actor_to_scene(actor:, scene:)
      remove_actor_from_scene(actor:)

      actor.current_scene = scene

      event = Ephesus::Core::Commands::ConnectActor::Event.new(actor)

      enqueue_event(event:, scene:)

      nil
    end

    # @private
    def handle_event(_) = nil

    # Removes the actor from its current scene.
    #
    # If the actor has a current scene, enqueues a DisconnectActor event for the
    # scene.
    #
    # @param actor [Ephesus::Core::Actor] the actor to remove from its scene.
    #
    # @return [void]
    def remove_actor_from_scene(actor:)
      scene = actor.current_scene

      return unless scene

      actor.current_scene = nil

      event = Ephesus::Core::Commands::DisconnectActor::Event.new(actor)

      enqueue_event(event:, scene:)

      nil
    end

    # Removes the connection from the engine.
    #
    # If the connection actor belongs to a scene, removes the actor from the
    # scene.
    #
    # @param [Ephesus::Core::Connection] the connection to remove.
    #
    # @return [void]
    def remove_connection(connection)
      remove_actor_from_scene(actor: connection.actor) if connection.actor

      @connections.delete(connection.id)

      unsubscribe(connection, channel: :events)

      nil
    end

    private

    attr_reader :actors

    attr_reader :connections

    def build_actor(_connection)
      Ephesus::Core::Actor.new
    end

    def default_scene = nil

    def enqueue_event(**) = nil
  end
end
