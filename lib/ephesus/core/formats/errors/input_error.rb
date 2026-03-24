# frozen_string_literal: true

require 'cuprum/error'

require 'ephesus/core/formats/errors'

module Ephesus::Core::Formats::Errors
  # Abstract error returned when formatting input events.
  class InputError < Cuprum::Error
    # Short string used to identify the type of error.
    TYPE = 'ephesus.core.formats.errors.input_error'

    # @param event [Ephesus::Core::Message] the received input event.
    # @param message [String] the message to display.
    # @param scene [Ephesus::Core::Scene] the current scene for the connection.
    def initialize(event:, message:, scene:)
      @event = event
      @scene = scene

      super
    end

    # @return [Ephesus::Core::Message] the received input event.
    attr_reader :event

    # @retirn [Ephesus::Core::Scene] the current scene for the connection.
    attr_reader :scene

    private

    def as_json_data
      {
        'event' => event.as_json,
        'scene' => scene.as_json
      }
    end
  end
end
