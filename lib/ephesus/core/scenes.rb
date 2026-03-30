# frozen_string_literal: true

require 'ephesus/core'

module Ephesus::Core
  # Namespace for functionality implementing or applying Scenes.
  module Scenes
    autoload :EventHandling, 'ephesus/core/scenes/event_handling'
    autoload :SideEffects,   'ephesus/core/scenes/side_effects'
  end
end
