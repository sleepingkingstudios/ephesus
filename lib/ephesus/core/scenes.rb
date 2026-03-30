# frozen_string_literal: true

require 'ephesus/core'

module Ephesus::Core
  # Namespace for functionality implementing or applying Scenes.
  module Scenes
    autoload :Builder,       'ephesus/core/scenes/builder'
    autoload :EventHandling, 'ephesus/core/scenes/event_handling'
    autoload :Pool,          'ephesus/core/scenes/pool'
    autoload :SideEffects,   'ephesus/core/scenes/side_effects'
  end
end
