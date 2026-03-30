# frozen_string_literal: true

require 'securerandom'

require 'ephesus/core'
require 'ephesus/core/messages/typing'
require 'ephesus/core/messaging/publisher'
require 'ephesus/core/scenes/event_handling'

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
    include Ephesus::Core::Scenes::EventHandling

    # Exception raised when a handler is not found for a side effect.
    class UnhandledSideEffectError < StandardError; end

    INSTANCE_VARIABLES_TO_INSPECT = %i[@id @type].freeze
    private_constant :INSTANCE_VARIABLES_TO_INSPECT

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

    # @return [Hash] a JSON-compatible representating of the scene.
    def as_json = { 'id' => id, 'type' => type }

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

    def instance_variables_to_inspect = INSTANCE_VARIABLES_TO_INSPECT

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

    def unhandled_side_effect_message_for(side_effect, details)
      details_data = details.map(&:inspect).join(', ')

      "no handler found for side effect #{side_effect.inspect} " \
        "(#{details_data})"
    end
  end
end
