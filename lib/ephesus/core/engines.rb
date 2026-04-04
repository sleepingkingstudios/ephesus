# frozen_string_literal: true

require 'ephesus/core'

module Ephesus::Core
  # Namespace for functionality implementing engines.
  module Engines
    autoload :SceneManagement, 'ephesus/core/engines/scene_management'
  end
end
