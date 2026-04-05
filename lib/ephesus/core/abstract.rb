# frozen_string_literal: true

require 'sleeping_king_studios/tools/toolbox/mixin'

require 'ephesus/core'

module Ephesus::Core
  # Shared functionality for defining abstract classes.
  module Abstract
    extend SleepingKingStudios::Tools::Toolbox::Mixin

    # Exception raised when setting a static option on an abstract class.
    class AbstractClassError < StandardError; end

    # Class methods extended onto the class when Abstract is included.
    module ClassMethods
      # @return [true, false] true if the class is an abstract class, otherwise
      #   false.
      def abstract? = false
    end
  end
end
