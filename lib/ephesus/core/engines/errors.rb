# frozen_string_literal: true

require 'ephesus/core/engines'

module Ephesus::Core::Engines
  # Namespace for errors returned by engines.
  module Errors
    autoload :ActorNotAssignedScene,
      'ephesus/core/engines/errors/actor_not_assigned_scene'
    autoload :MissingActor,
      'ephesus/core/engines/errors/missing_actor'
  end
end
