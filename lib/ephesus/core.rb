# frozen_string_literal: true

# An engine and toolkit for developing text games in Ruby.
module Ephesus
  # Implements functionality for Ephesus.
  module Core
    autoload :Command, 'ephesus/core/command'
    autoload :Events,  'ephesus/core/events'
    autoload :Message, 'ephesus/core/message'
    autoload :Scene,   'ephesus/core/scene'
    autoload :State,   'ephesus/core/state'
    autoload :Typing,  'ephesus/core/typing'
  end
end
