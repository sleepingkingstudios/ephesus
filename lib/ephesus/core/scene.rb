# frozen_string_literal: true

require 'securerandom'

require 'ephesus/core'
require 'ephesus/core/messages/typing'
require 'ephesus/core/messaging/publisher'
require 'ephesus/core/scenes/event_handling'
require 'ephesus/core/scenes/side_effects'

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
  class Scene
    include Ephesus::Core::Messages::Typing
    include Ephesus::Core::Messaging::Publisher
    include Ephesus::Core::Scenes::EventHandling
    include Ephesus::Core::Scenes::SideEffects

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

    # @return [String] a human-readable representation of the scene.
    def inspect
      tools
        .object_tools
        .format_inspect(self, address: false, properties: properties_to_inspect)
    end

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

    def properties_to_inspect = { id:, type: }

    def tools = @tools ||= SleepingKingStudios::Tools::Toolbelt.instance
  end
end
