# frozen_string_literal: true

require 'cuprum/error'

require 'ephesus/core/engines/errors'

module Ephesus::Core::Engines::Errors
  # Error returned when handling input for a connection without an actor.
  class MissingActor < Cuprum::Error
    # Short string used to identify the type of error.
    TYPE = 'ephesus.core.engines.errors.missing_actor'

    # @param message [String] an optional message to display.
    def initialize(message: nil)
      super(message: default_message(message))
    end

    private

    def default_message(message)
      str = 'connection does not have an actor'

      return str unless message && !message.empty?

      "#{message} - #{str}"
    end
  end
end
