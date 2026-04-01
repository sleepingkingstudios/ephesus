# frozen_string_literal: true

require 'ephesus/core/abstract'
require 'ephesus/core/command'
require 'ephesus/core/commands/connect_actor'
require 'ephesus/core/commands/disconnect_actor'
require 'ephesus/core/scenes'

module Ephesus::Core::Scenes
  # Functionality for registering and calling event handlers for a scene.
  module EventHandling
    extend  SleepingKingStudios::Tools::Toolbox::Mixin
    include Ephesus::Core::Abstract

    # Exception raised when a handler is not found for an event.
    class UnhandledEventError < StandardError; end

    # Class methods extended onto Scene when including EventHandling.
    module ClassMethods
      DEFAULT_EVENT_HANDLERS =
        [
          Ephesus::Core::Commands::ConnectActor,
          Ephesus::Core::Commands::DisconnectActor
        ]
        .to_h { |command_class| [command_class.type, command_class] }
        .freeze

      # @overload handle_event(command_class)
      #   Registers the command class to handle events of the same type.
      #
      #   @param command_class [Class] the command class used to handle matching
      #     events.
      #
      # @overload handle_event(event_type, command_class)
      #   Registers the command class to handle events of the specified type.
      #
      #   @param event_type [Event, String] the event or event type to match.
      #   @param command_class [Class] the command class used to handle matching
      #     events.
      def handle_event(event_or_command, maybe_command = nil)
        if abstract?
          raise self::AbstractClassError,
            "unable to add event handler for abstract class #{name}"
        end

        event_type, command_class =
          resolve_event_and_command(event_or_command, maybe_command)

        validate_command_class(command_class)
        validate_event_type(event_type)

        own_handled_events[event_type.to_s] = command_class
      end

      # @overload handle_event(command_class)
      #   Checks if the scene can handle events of the specified class.
      #
      #   @param command_class [Class] the command class to check.
      #
      #   @return [true, false] true if the scene has a registered handler for
      #     events matching the class type; otherwise false.
      #
      # @overload handle_event(event_type)
      #   Checks if the scene can handle events of the specified type.
      #
      #   @param event_type [Event, String] the event or event type to check.
      #
      #   @return [true, false] true if the scene has a registered handler for
      #     events matching the event type; otherwise false.
      def handle_event?(event_or_command)
        event_type = event_or_command
        event_type = event_type.type if event_type.respond_to?(:type)

        handled_events.key?(event_type.to_s)
      end

      # @return [Hash{String => Class}] the event types handled by the scene and
      #   the corresponding Command classes.
      def handled_events
        return DEFAULT_EVENT_HANDLERS if self == Ephesus::Core::Scene

        superclass.handled_events.merge(own_handled_events)
      end

      private

      def own_handled_events = @own_handled_events ||= {}

      def resolve_event_and_command(event_or_command, maybe_command)
        if maybe_command.nil? && event_or_command.respond_to?(:type)
          return [event_or_command.type, event_or_command]
        elsif maybe_command.nil?
          return [nil, event_or_command]
        end

        event_type = event_or_command
        event_type = event_type.type if event_type.respond_to?(:type)

        [event_type, maybe_command]
      end

      def tools = @tools ||= SleepingKingStudios::Tools::Toolbelt.instance

      def validate_command_class(command_class)
        tools.assertions.validate_class(command_class, as: 'command_class')
        tools.assertions.validate_inherits_from(
          command_class,
          as:       'command_class',
          expected: Ephesus::Core::Command
        )
      end

      def validate_event_type(event_type)
        Ephesus::Core::Messages::Typing
          .validate_type(event_type, as: 'event_type')
      end
    end

    private

    def event_handler_for(event)
      command_class = self.class.handled_events.fetch(event.type) do
        raise UnhandledEventError, unhandled_event_message_for(event)
      end

      command_class.new
    end

    def handle_event(event)
      command = event_handler_for(event)
      result  = command.call(event:, state:)

      if result.success?
        @state, side_effects = resolve_success(result.value)
      else
        side_effects = resolve_failure(result.value)
      end

      handle_side_effects(side_effects)

      result
    end

    def resolve_failure(value)
      value.is_a?(Array) ? value : nil
    end

    def resolve_success(value)
      return value if value.is_a?(Ephesus::Core::State)

      return @state unless value.is_a?(Array)

      head, *tail = value

      return [head, tail] if head.is_a?(Ephesus::Core::State)

      [@state, [head, *tail]]
    end

    def unhandled_event_message_for(event)
      data    = event.to_h
      message = "no event handler found for event #{event.type}"
      message = "#{message} (#{data.inspect})" unless data.empty?
      message
    end
  end
end
