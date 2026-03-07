# frozen_string_literal: true

# An engine and toolkit for developing text games in Ruby.
module Ephesus
  # Implements functionality for Ephesus.
  module Core
    autoload :Event,  'ephesus/core/event'
    autoload :Events, 'ephesus/core/events'
    autoload :Typing, 'ephesus/core/typing'
  end
end
