# frozen_string_literal: true

require 'cuprum/error'

require 'ephesus/core/engines/errors'

module Ephesus::Core::Engines::Errors
  # Error returned when handling input for an actor without an assigned scene.
  class ActorNotAssignedScene < Cuprum::Error
    # Short string used to identify the type of error.
    TYPE = 'ephesus.core.engines.errors.actor_not_assigned_scene'

    # @param actor [Ephesus::Core::Actor] the unassigned actor.
    # @param message [String] an optional message to display.
    def initialize(actor:, message: nil)
      @actor = actor

      super(actor:, message: default_message(message))
    end

    # @return [Ephesus::Core::Actor] the unassigned actor.
    attr_reader :actor

    private

    def as_json_data = { 'actor' => actor.as_json }

    def default_message(message)
      str = "actor #{actor.inspect} is not assigned to a scene"

      return str unless message && !message.empty?

      "#{message} - #{str}"
    end
  end
end
