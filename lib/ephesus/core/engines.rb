# frozen_string_literal: true

require 'ephesus/core'

module Ephesus::Core
  # Namespace for functionality implementing engines.
  module Engines
    autoload :ConnectionManagement, 'ephesus/core/engines/connection_management'
    autoload :SceneManagement,      'ephesus/core/engines/scene_management'
  end
end
