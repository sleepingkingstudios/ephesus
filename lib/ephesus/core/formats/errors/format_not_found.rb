# frozen_string_literal: true

require 'cuprum/error'

require 'ephesus/core/formats/errors'

module Ephesus::Core::Formats::Errors
  # Error returned when trying to reference an undefined format.
  class FormatNotFound < Cuprum::Error
    # Short string used to identify the type of error.
    TYPE = 'ephesus.core.formats.errors.format_not_found'

    # @param format [String] the expected format.
    # @param message [String] an optional message to display.
    # @param valid_formats [Array<String>] the valid formats for the connection.
    def initialize(format:, message: nil, valid_formats: [])
      @format        = format
      @valid_formats = valid_formats

      super(format:, message: default_message(message), valid_formats:)
    end

    # @return format [String] the expected format.
    attr_reader :format

    # @return [Array<String>] the valid formats for the connection.
    attr_reader :valid_formats

    private

    def as_json_data = { 'format' => format, 'valid_formats' => valid_formats }

    def default_message(message)
      str = "format not found with type #{format.inspect}"

      if valid_formats && !valid_formats.empty?
        str += " (valid formats are #{valid_formats.map(&:inspect).join(', ')})"
      end

      return str unless message && !message.empty?

      "#{message} - #{str}"
    end
  end
end
