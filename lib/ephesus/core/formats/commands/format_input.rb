# frozen_string_literal: true

require 'cuprum/command'

require 'ephesus/core/formats/commands'
require 'ephesus/core/formats/errors/unhandled_event'

module Ephesus::Core::Formats::Commands
  # Converts an input event for the current format to a scene input event.
  class FormatInput < Cuprum::Command
    # @param scene [Ephesus::Core::Scene] the current scene to parse inputs for.
    # @param options [Hash] additional options for parsing inputs.
    def initialize(scene:, **options)
      super()

      @scene   = scene
      @options = options
    end

    # @return [Hash] additional options for parsing inputs.
    attr_reader :options

    # @return [Ephesus::Core::Scene] the current scene to parse inputs for.
    attr_reader :scene

    # @!method call(event)
    #   Converts the input event to a scene input.
    #
    #   @param event [Ephesus::Core::Message] the input event to process.
    #
    #   @return [Cuprum::Result<Ephesus::Core::Message>] the formatted event.
    #
    #   @return [Cuprum::Result<Ephesus::Core::Formats::Errors::UnhandledEvent]
    #     if the scene is not configured to process the formatted event.

    private

    def check_if_event_handled(input_message)
      return if scene.class.handle_event?(input_message)

      failure(unhandled_event_error(input_message))
    end

    def format_input(input_message) = input_message

    def process(input_message)
      input_message = step { format_input(input_message) }

      step { check_if_event_handled(input_message) }

      input_message
    end

    def unhandled_event_error(input_message)
      Ephesus::Core::Formats::Errors::UnhandledEvent
        .new(event: input_message, scene:)
    end
  end
end
