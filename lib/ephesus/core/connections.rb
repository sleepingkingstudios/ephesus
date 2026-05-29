# frozen_string_literal: true

require 'ephesus/core'

module Ephesus::Core
  # Namespace for functionality implementing connections.
  module Connections
    autoload :Buffered, 'ephesus/core/connections/buffered'
  end
end
