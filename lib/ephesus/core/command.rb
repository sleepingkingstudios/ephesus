# frozen_string_literal: true

require 'cuprum'

require 'ephesus/core'
require 'ephesus/core/typing'

module Ephesus::Core
  # Command class that handles an event for a scene.
  class Command < Cuprum::Command
    include Ephesus::Core::Typing

    # @return [Ephesus::Core::Event] the handled event.
    attr_reader :event

    # @return [Array<Symbol, Object>] side effects to be processed by the scene.
    attr_reader :side_effects

    # @return [Ephesus::Core::State] the current state of the scene.
    attr_reader :state

    # Calls the command and returns a Cuprum::Result.
    #
    # A successful result must either have a value equal to the updated state,
    # or an Array with the first item being the updated state and remaining
    # values the side effects to be processed by the scene.
    #
    # @param event [Ephesus::Core::Event] the handled event.
    # @param state [Ephesus::Core::State] the initial state of the scene.
    #
    # @return [Cuprum::Result] the command result.
    def call(event:, state:)
      @event        = event
      @state        = state
      @side_effects = []

      super
    end

    private

    def success(value = nil)
      return super if value

      return super(state) if side_effects.empty?

      super([state, *side_effects])
    end
  end
end
