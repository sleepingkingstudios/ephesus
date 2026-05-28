# frozen_string_literal: true

require 'ephesus/core/actor'
require 'ephesus/core/engines'

module Ephesus::Core::Engines
  # Methods for managing actors and connections for engines.
  module ConnectionManagement
    include Ephesus::Core::Messaging::Subscriber

    # Exception raised when unable to add a connection.
    class ConnectionError < StandardError; end

    def initialize(**)
      super

      @actors      = {}
      @connections = {}
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

    # @overload connect(connection_class = Ephesus::Core::Connection, format:, **options)
    #   Creates a connection and adds the connection to the engine.
    #
    #   The connection is initialized using the given connection class (or
    #   Ephesus::Core::Connection by default), the given :format and options,
    #   and any #connection_options defined by the engine. In case of a
    #   conflict, options given override the engine's connection options.
    #
    #   Once the connection is created:
    #
    #   - The connection is added to engine.connections.
    #   - The engine generates an actor using #build_actor and assigns it to the
    #     connection.
    #   - The engine subscribes to events from the connection on the :events
    #     channel.
    #   - If the engine defines a default scene, automatically adds the
    #     connection to the default scene.
    #
    #   @param connection_class [Class] the class of connection to create.
    #     Defaults to Ephesus::Core::Connection.
    #   @param format [String, Symbol] the format for the connection.
    #   @param options [Hash] additional options for the connection.
    #
    #   @return [Ephesus::Core::Connection] the generated connection.
    def connect(
      connection_class = Ephesus::Core::Connection,
      format:,
      **
    )
      connection_class
        .new(format:, **connection_options, **)
        .tap { |connection| add_connection(connection) }
    end

    # Removes the connection from the engine.
    #
    # If the connection actor belongs to a scene, removes the actor from the
    # scene.
    #
    # @param [Ephesus::Core::Connection] the connection to remove.
    #
    # @return [Ephesus::Core::Connection] the removed connection.
    def disconnect(connection)
      remove_actor_from_scene(actor: connection.actor) if connection.actor

      @connections.delete(connection.id)

      unsubscribe(connection, channel: :events)

      connection
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

    private

    attr_reader :actors

    attr_reader :connections

    def add_connection(connection)
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

    def build_actor(_connection)
      Ephesus::Core::Actor.new
    end

    def connection_options = {}

    def default_scene = nil

    def enqueue_event(**) = nil
  end
end
