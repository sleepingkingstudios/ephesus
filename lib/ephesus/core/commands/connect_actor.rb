# frozen_string_literal: true

require 'ephesus/core/commands'

module Ephesus::Core::Commands
  # Command for connecting an Actor to a Scene.
  class ConnectActor < Ephesus::Core::Command
    # Event for connecting an Actor to a Scene.
    Event = Ephesus::Core::Message.define(:actor)

    private

    def process(event:, state:)
      actor  = event.actor
      @state = state.set('actors', actor.id, value: actor)

      options = {
        channel:     :notifications,
        method_name: :handle_notification,
        subscriber:  actor
      }

      side_effects << [:subscribe, options]

      success
    end
  end
end
