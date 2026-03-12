# frozen_string_literal: true

require 'ephesus/core/messages'
require 'ephesus/core/messages/typing'

module Ephesus::Core::Messages
  # Extends defining messages to allow setting a static type identifier.
  module Definitions
    # Class methods prepended on the singleton class when including Definitions.
    module ClassMethods
      # Defines a new Event class including the members/methods of this class.
      #
      # @param symbols [Array<Symbol>] additional Event members to define. Any
      #   members listed here will be appended to the members defined on the
      #   parent Event class.
      # @param type [String] the type identifier for the Event. Defaults to nil.
      #
      # @yield additional methods to define on the new Data class.
      def define(*symbols, type: nil, &)
        super(*symbols, &).tap do |data_class|
          next unless type

          Ephesus::Core::Messages::Typing.validate_type(type)

          data_class.const_set(:TYPE, type)
        end
      end
    end

    class << self
      private

      def included(other)
        super

        other.singleton_class.prepend(ClassMethods)
      end
    end
  end
end
