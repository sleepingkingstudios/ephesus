# frozen_string_literal: true

require 'ephesus/core/engines'

module Ephesus::Core::Engines
  # Engine that runs input events immediately in the current thread/fiber.
  module Synchronous
    private

    def enqueue_event(event:, scene:)
      super.tap { scene.call(thread_safe: false) }
    end
  end
end
