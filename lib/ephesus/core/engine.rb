# frozen_string_literal: true

require 'ephesus/core'
require 'ephesus/core/engines/connection_management'
require 'ephesus/core/engines/scene_management'

module Ephesus::Core
  # Manages and runs scenes and external connections.
  class Engine
    include Ephesus::Core::Engines::ConnectionManagement
    include Ephesus::Core::Engines::SceneManagement

    # @return [true, false] true if the class is an abstract class, otherwise
    #   false.
    def self.abstract? = self == Ephesus::Core::Engine
  end
end
