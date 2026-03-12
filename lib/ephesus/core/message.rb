# frozen_string_literal: true

require 'sleeping_king_studios/tools/toolbelt'
require 'sleeping_king_studios/tools/toolbox/heritable_data'

require 'ephesus/core'
require 'ephesus/core/typing'

module Ephesus::Core
  # Data class used to communicate and store changes across an application.
  Message = SleepingKingStudios::Tools::Toolbox::HeritableData.define do
    class << self
      private

      def included(other)
        super

        if other.is_a?(Class)
          other.include(Ephesus::Core::Messages::Definitions)
          other.include(Ephesus::Core::Typing)
        else
          other.define_singleton_method(:included) do |inner|
            inner.include(Ephesus::Core::Messages::Definitions)
            inner.include(Ephesus::Core::Typing)
          end
        end
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

    # @return [String] the defined type for the message.
    def type = self.class.type
  end
end
