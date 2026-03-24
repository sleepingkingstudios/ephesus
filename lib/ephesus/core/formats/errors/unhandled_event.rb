# frozen_string_literal: true

require 'cuprum/error'

require 'ephesus/core/formats/errors'
require 'ephesus/core/formats/errors/input_error'

module Ephesus::Core::Formats::Errors
  # Error returned when an input event is not handled by the scene.
  class UnhandledEvent < Ephesus::Core::Formats::Errors::InputError
    # Short string used to identify the type of error.
    TYPE = 'ephesus.core.formats.errors.unhandled_event'

    # @param event [Ephesus::Core::Message] the received input event.
    # @param scene [Ephesus::Core::Scene] the current scene for the connection.
    def initialize(event:, scene:)
      super(event:, scene:, message: default_message(event:, scene:))
    end

    private

    def default_message(event:, scene:)
      "Unhandled event #{event.type.inspect} for scene #{scene.type.inspect}"
    end
  end
end
