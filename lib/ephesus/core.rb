# frozen_string_literal: true

# An engine and toolkit for developing text games in Ruby.
module Ephesus
  # Implements functionality for Ephesus.
  module Core
    autoload :Actor,      'ephesus/core/actor'
    autoload :Command,    'ephesus/core/command'
    autoload :Commands,   'ephesus/core/commands'
    autoload :Connection, 'ephesus/core/connection'
    autoload :Message,    'ephesus/core/message'
    autoload :Messages,   'ephesus/core/messages'
    autoload :Scene,      'ephesus/core/scene'
    autoload :State,      'ephesus/core/state'
  end
end
