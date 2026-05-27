# frozen_string_literal: true

require 'async'
require 'async/semaphore'

require 'ephesus/core/engines'

module Ephesus::Core::Engines
  # Engine that runs input events in fibers using Async tasks.
  module Asynchronous
    # @param worker_limit [Integer] the maximum number of simultaneous workers
    #   processing scene events.
    def initialize(worker_limit: 5, **)
      super(**)

      @mutex        = Thread::Mutex.new
      @running      = false
      @worker_limit = worker_limit

      initialize_workers
    end

    # @return [true, false] true if the engine is currently processing scene
    #   events, otherwise false.
    def running?
      @mutex.synchronize { @running }
    end

    # Starts the Async tasks processing scene events.
    #
    # @return [void]
    def start
      @mutex.synchronize do
        return if @running

        @running = true

        scenes.each_value do |scene|
          next if scene.queue_empty?

          workers.async { scene.call }
        end
      end
    end

    # Stops any running Async tasks processing scene events.
    #
    # @return [void]
    def stop
      @mutex.synchronize do
        initialize_workers

        @running = false
      end
    end

    private

    attr_reader :worker_limit

    attr_reader :workers

    def enqueue_event(scene:, **)
      @mutex.synchronize do
        super.tap { workers.async { scene.call } if @running }
      end
    end

    def initialize_workers
      @barrier&.wait

      @barrier = Async::Barrier.new
      @workers = Async::Semaphore.new(worker_limit, parent: @barrier)
    end
  end
end
