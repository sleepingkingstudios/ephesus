# frozen_string_literal: true

require 'sleeping_king_studios/tools/toolbelt'
require 'sleeping_king_studios/tools/toolbox/mixin'

require 'ephesus/core'

module Ephesus::Core
  # Utility for defining a default type identifier based on the class name.
  module Typing
    include SleepingKingStudios::Tools::Toolbox::Mixin

    # String patterns to exclude when occuring at the end of a name segment.
    EXCLUSIONS = %w[action command event notification].freeze

    EXCLUDED_PATTERN = /_?(#{EXCLUSIONS.join('|')})\z/
    private_constant :EXCLUDED_PATTERN

    # Format used to validate type identifiers.
    FORMAT = /\A[a-z_]+(\.[a-z_]+)*\z/

    # Class methods to extend when including Typing in a Class or Module.
    module ClassMethods
      # The type identifier for the class.
      #
      # If the class defines a :TYPE constant, returns the value of :TYPE.
      # Otherwise, generates and caches a default value based on the class name:
      #
      # - The class name is split by '::' double colons. If the class is
      #   anonymous, traverses the ancestors until a Class with non-nil .name is
      #   found.
      # - Each segment is converted to camel_case.
      # - If the segment ends with an excluded pattern (such as "action" or
      #   "event", that pattern and any preceding underscore is removed from the
      #   segment).
      # - Any empty segments are removed.
      # - All remaining segments are joined with '.' periods.
      #
      # @return [String] the type identifier.
      #
      # @example A named class.
      #   class Game::Events::UpdateScore
      #     include Ephesus::Core::Typing
      #   end
      #
      #   Game::Events::UpdateScore.type
      #   #=> 'game.events.update_score'
      #
      # @example A named class with excluded segments.
      #   class Game::UpdateCommand::Notification
      #     include Ephesus::Core::Typing
      #   end
      #
      #   Game::UpdateCommand::Notification.type
      #   #=> 'game.update'
      def type
        @type ||=
          const_defined?(:TYPE) ? self::TYPE : Typing.default_type_for(self)
      end

      private

      def included(other)
        super

        other.extend(ClassMethods)
      end
    end

    class << self
      # Generates the default type identifier for a class.
      #
      # @return [String] the type identifier.
      def default_type_for(mod)
        class_name = class_name_for(mod)

        return unless class_name&.length&.nonzero?

        class_name
          .split('::')
          .map { |str| normalize_partial_name(str) }
          .then { |ary| join_names(*ary) }
      end

      # Verifies that the given type is a valid type identifier.
      #
      # If the given value is not a properly formatted String, raises an
      # ArgumentError.
      #
      # @param type [Object] the type to validate.
      #
      # @return [String] the validated type.
      def validate_type(type)
        tools.assertions.validate_name(type, as: 'type')

        message =
          'type must be a lowercase underscored string separated by periods'

        tools.assertions.validate_matches(
          type.to_s,
          expected: FORMAT,
          message:
        )

        type.to_s
      end

      private

      def class_name_for(mod)
        mod.ancestors.each do |ancestor|
          return nil if ancestor == Object || ancestor == Data # rubocop:disable Style/MultipleComparison

          return ancestor.name if ancestor.is_a?(Class) && ancestor.name
        end
      end

      def included(other)
        super

        other.extend(ClassMethods)
      end

      def join_names(*names)
        names
          .reject { |str| str.nil? || str.empty? }
          .join('.')
          .then { |str| str.empty? ? nil : str }
      end

      def normalize_partial_name(str)
        tools
          .string_tools
          .underscore(str)
          .sub(EXCLUDED_PATTERN, '')
      end

      def tools = SleepingKingStudios::Tools::Toolbelt.instance
    end
  end
end
