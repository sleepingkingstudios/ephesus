# frozen_string_literal: true

# An engine and toolkit for developing text games in Ruby.
module Ephesus
  # Implements functionality for Ephesus.
  module Core
    autoload :Command, 'ephesus/core/command'
    autoload :Event,   'ephesus/core/event'
    autoload :Events,  'ephesus/core/events'
    autoload :State,   'ephesus/core/state'
    autoload :Typing,  'ephesus/core/typing'
  end
end
