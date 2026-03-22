# frozen_string_literal: true

require 'sleeping_king_studios/tools/toolbelt'
require 'sleeping_king_studios/tools/toolbox/heritable_data'

require 'ephesus/core'
require 'ephesus/core/messages/definitions'
require 'ephesus/core/messages/typing'

module Ephesus::Core
  # Data class used to communicate and store changes across an application.
  Message = SleepingKingStudios::Tools::Toolbox::HeritableData.define do # rubocop:disable Metrics/BlockLength
    class << self
      private

      def included(other)
        super

        other.include Ephesus::Core::Messages::Definitions
        other.include Ephesus::Core::Messages::Typing
      end
    end

    # Returns the value for the matching property.
    #
    # @param property_name [String, Symbol] the name of the property to return.
    #
    # @return [Object] the value of the property.
    #
    # @raise [NoMethodError] if the property is not a member of the class.
    def [](property_name)
      member_name =
        property_name.is_a?(String) ? property_name.intern : property_name

      return public_send(member_name) if members.include?(member_name)

      raise NoMethodError, "member not found: #{property_name.inspect}"
    end

    # @return [Hash] a JSON-compatible representating of the message.
    def as_json
      members.each_with_object({ 'type' => type }) do |member, hsh|
        hsh[member.to_s] = convert_to_json(self[member])
      end
    end

    # @return [String] the defined type for the message.
    def type = self.class.type

    private

    def convert_to_json(value) # rubocop:disable Metrics/MethodLength
      return value.as_json if value.respond_to?(:as_json)

      case value
      when NilClass, FalseClass, TrueClass, Integer, Float
        value
      when Array
        value.map { |item| convert_to_json(item) }
      when Hash
        value.to_h { |key, value| [key.to_s, convert_to_json(value)] }
      else
        value.to_s
      end
    end
  end
end
