# frozen_string_literal: true

require 'ephesus/core'

module Ephesus::Core
  # Namespace for command implementations.
  module Commands
    autoload :ConnectActor,    'ephesus/core/commands/connect_actor'
    autoload :DisconnectActor, 'ephesus/core/commands/disconnect_actor'
  end
end
