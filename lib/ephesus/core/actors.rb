# frozen_string_literal: true

require 'ephesus/core'

module Ephesus::Core
  # Namespace for Actor implementations.
  module Actors
    autoload :ExternalActor, 'ephesus/core/actors/external_actor'
  end
end
