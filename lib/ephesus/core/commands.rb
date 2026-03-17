# frozen_string_literal: true

require 'ephesus/core'

module Ephesus::Core
  # Namespace for command implementations.
  module Commands
    autoload :ConnectActor, 'ephesus/core/commands/connect_actor'
  end
end
