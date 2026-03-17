# frozen_string_literal: true

require 'ephesus/core/commands'

module Ephesus::Core::Commands
  # Command for disconnecting an Actor from a Scene.
  class DisconnectActor < Ephesus::Core::Command
    # Event for connecting an Actor to a Scene.
    Event = Ephesus::Core::Message.define(:actor)

    private

    def process(event:, state:)
      actor  = event.actor
      @state = state.delete('actors', actor.id)

      options = {
        channel:    :notifications,
        subscriber: actor
      }

      side_effects << [:unsubscribe, options]

      success
    end
  end
end
