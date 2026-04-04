# frozen_string_literal: true

# An engine and toolkit for developing text games in Ruby.
module Ephesus
  # Implements functionality for Ephesus.
  module Core
    autoload :Abstract,   'ephesus/core/abstract'
    autoload :Actor,      'ephesus/core/actor'
    autoload :Actors,     'ephesus/core/actors'
    autoload :Command,    'ephesus/core/command'
    autoload :Commands,   'ephesus/core/commands'
    autoload :Connection, 'ephesus/core/connection'
    autoload :Engines,    'ephesus/core/engines'
    autoload :Formats,    'ephesus/core/formats'
    autoload :Message,    'ephesus/core/message'
    autoload :Messages,   'ephesus/core/messages'
    autoload :Messaging,  'ephesus/core/messaging'
    autoload :Scene,      'ephesus/core/scene'
    autoload :Scenes,     'ephesus/core/scenes'
    autoload :State,      'ephesus/core/state'
  end
end
