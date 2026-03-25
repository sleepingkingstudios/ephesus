# frozen_string_literal: true

require 'cuprum/error'

require 'ephesus/core/formats/errors'

module Ephesus::Core::Formats::Errors
  # Abstract error returned when formatting output events.
  class OutputError < Cuprum::Error
    # Short string used to identify the type of error.
    TYPE = 'ephesus.core.formats.errors.output_error'

    # @param notification [Ephesus::Core::Message] the received output
    #   notification.
    # @param message [String] the message to display.
    def initialize(message:, notification:)
      @notification = notification

      super
    end

    # @return [Ephesus::Core::Message] the received output notification.
    attr_reader :notification

    private

    def as_json_data
      { 'notification' => notification.as_json }
    end
  end
end
