# frozen_string_literal: true

require 'securerandom'

require 'ephesus/core'
require 'ephesus/core/command'
require 'ephesus/core/commands/connect_actor'
require 'ephesus/core/commands/disconnect_actor'
require 'ephesus/core/messages/typing'
require 'ephesus/core/messaging/publisher'

module Ephesus::Core
  # Interactive scene that enqueues and processes input events.
  #
  # Each scene tracks events using two data structures - a queue and a stack.
  # Input events are always added to the queue. Each time the scene is called,
  # the first item in the queue is removed and processed. Processing an event
  # may trigger additional events, which are pushed onto the event stack; each
  # event on the stack is then handled until the stack is empty.
  #
  # Each event is handled using a command, which is passed the event and the
  # current state for the scene. A successful command result should return the
  # updated state and an optional list of side effects (such as notifying
  # listeners or pushing more events onto the stack). A failed result may also
  # return a list of side effects.
  class Scene # rubocop:disable Metrics/ClassLength
    include Ephesus::Core::Messages::Typing
    include Ephesus::Core::Messaging::Publisher

    # Exception raised when setting a static option on an abstract class.
    class AbstractClassError < StandardError; end

    # Exception raised when a handler is not found for an event.
    class UnhandledEventError < StandardError; end

    # Exception raised when a handler is not found for a side effect.
    class UnhandledSideEffectError < StandardError; end

    DEFAULT_EVENT_HANDLERS =
      [
        Ephesus::Core::Commands::ConnectActor,
        Ephesus::Core::Commands::DisconnectActor
      ]
      .to_h { |command_class| [command_class.type, command_class] }
      .freeze
    private_constant :DEFAULT_EVENT_HANDLERS

    class << self
      # @return [true, false] true if the class is an abstract class, otherwise
      #   false.
      def abstract? = self == Ephesus::Core::Scene

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
          raise AbstractClassError,
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

    # @param [Hash] the initial state for the scene. Will be merged onto the
    #   defined default state, if any.
    def initialize(state: {})
      @id          = SecureRandom.uuid_v7
      @event_queue = []
      @event_stack = []
      @state       = build_state(
        default_state.merge(tools.hash_tools.convert_keys_to_strings(state))
      )
    end

    # @return [String] a unique identifier for the scene.
    attr_reader :id

    # @return [Ephesus::Core::State] the current state for the scene.
    attr_reader :state

    # Handles the next queued event.
    #
    # Finds and calls the event handler for the next queued event. That event
    # may push additional events onto the event stack, in which case #call will
    # continue to handle events until the event stack is empty.
    #
    # If the event queue is empty, does nothing.
    #
    # @return [self]
    def call
      event = event_queue.shift

      return self unless event

      handle_event(event)

      handle_event(event) while (event = event_stack.pop)

      self
    end

    # Adds the event to the event queue for the scene.
    def enqueue_event(event) = event_queue << event
    alias enqueue enqueue_event

    # @return [String] the type identifier for the scene.
    def type = self.class.type

    private

    attr_reader :event_queue

    attr_reader :event_stack

    def build_state(state)
      state_class =
        if self.class.const_defined?(:State)
          self.class.const_get(:State)
        else
          Ephesus::Core::State
        end

      state_class.new(state)
    end

    def default_state = { 'actors' => {} }

    def each_actor(&)
      return enum_for(:each_actor) unless block_given?

      @state.get('actors').each_value(&)
    end

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

    def handle_notify(notification) # rubocop:disable Metrics/MethodLength
      context = notification.context.merge(scene_type: type)

      if notification.current_actor
        notification
          .current_actor
          .handle_notification(notification.with(context:))
      else
        each_actor do |actor|
          actor.handle_notification(
            notification.with(current_actor: actor, context:)
          )
        end
      end
    end

    def handle_push_event(event)
      event_stack << event
    end

    def handle_side_effect(side_effect, *details)
      case side_effect
      when :notify      then handle_notify(*details)
      when :push_event  then handle_push_event(*details)
      when :subscribe   then handle_subscribe(**details.first)
      when :unsubscribe then handle_unsubscribe(**details.first)
      else
        raise UnhandledSideEffectError,
          unhandled_side_effect_message_for(side_effect, details)
      end
    end

    def handle_side_effects(side_effects)
      side_effects&.each do |maybe_side_effect|
        next unless maybe_side_effect.is_a?(Array)
        next unless maybe_side_effect.first.is_a?(Symbol)

        side_effect, *details = maybe_side_effect

        handle_side_effect(side_effect, *details)
      end
    end

    def handle_subscribe(subscriber:, **)
      subscriber.subscribe(self, **)
    end

    def handle_unsubscribe(subscriber:, **)
      subscriber.unsubscribe(self, **)
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

    def tools = @tools ||= SleepingKingStudios::Tools::Toolbelt.instance

    def unhandled_event_message_for(event)
      data    = event.to_h
      message = "no event handler found for event #{event.type}"
      message = "#{message} (#{data.inspect})" unless data.empty?
      message
    end

    def unhandled_side_effect_message_for(side_effect, details)
      details_data = details.map(&:inspect).join(', ')

      "no handler found for side effect #{side_effect.inspect} " \
        "(#{details_data})"
    end
  end
end
