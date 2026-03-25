# frozen_string_literal: true

require 'ephesus/core/formats'
require 'ephesus/core/formats/commands/format_input'

module Ephesus::Core::Formats
  # Defines methods for encapsulating IO processing for a single format.
  module Formatter
    # Converts an input event for the current format to a scene input event.
    #
    # @param event [Ephesus::Core::Message] the input event to process.
    # @param scene [Ephesus::Core::Scene] the current scene to parse inputs for.
    # @param options [Hash] additional options for parsing inputs.
    #
    # @return [Cuprum::Result<Ephesus::Core::Message>] the formatted event.
    #
    # @return [Cuprum::Result<Ephesus::Core::Formats::Errors::UnhandledEvent] if
    #   the scene is not configured to process the formatted event.
    def format_input(event:, scene:, **)
      input_formatter_for(scene:, **).call(event)
    end

    # Converts a notification to a formatted output event.
    #
    # @param notification [Ephesus::Core::Messages::Notification] the
    #   notification to process.
    # @param options [Hash] additional options for parsing outputs.
    #
    # @return [Cuprum::Result<Ephesus::Core::Message>] the formatted event.
    #
    # @return
    #   [Cuprum::Result<Ephesus::Core::Formats::Errors::UnhandledNotification]
    #   if the formatter is unable to process the notification..
    def format_output(notification:, **)
      output_formatter_for(**).call(notification)
    end

    private

    def input_formatter_for(scene:, **)
      Ephesus::Core::Formats::Commands::FormatInput.new(scene:, **)
    end

    def output_formatter_for(**)
      Ephesus::Core::Formats::Commands::FormatOutput.new(**)
    end
  end
end
