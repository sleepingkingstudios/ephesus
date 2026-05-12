# frozen_string_literal: true

require 'ephesus/core/scenes'

module Ephesus::Core::Scenes
  # Methods for processing queued events for a Scene.
  module Processing
    def initialize
      @mutex       = Thread::Mutex.new
      @event_queue = Thread::Queue.new
      @event_stack = []
      @processing  = false
    end

    # Adds the event to the event queue for the scene.
    def enqueue_event(event) = event_queue << event
    alias enqueue enqueue_event

    # Handles the next queued event.
    #
    # If the scene has no queued events, or if the scene is already processing
    # events, returns false. Otherwise, finds and calls the event handler for
    # the next queued event. That event may push additional events onto the
    # event stack, in which case #call will continue to handle events until the
    # event stack is empty. If any events were processed, returns true.
    #
    # If a batch size is provided, #call tracks the total number of processed
    # events. If the number of processed events is less than the batch size and
    # there are additional events in the queue, the scene will continue
    # processing queued events until the batch size is reached or the queue is
    # exhausted.
    #
    # While the scene is processing events, the #processing? flag is set to
    # true.
    #
    # @param batch_size [Integer] the number of total events to process before
    #   yielding control. This is a soft limit; events that stack other events
    #   are highly likely to exceed the batch size, after which the scene will
    #   yield control as normal.
    # @param thread_safe [true, false] if true, wraps execution in a mutex to
    #   ensure that multiple threads cannot process events concurrently. Set
    #   this value to false when calling the scene from a synchronous runner.
    #   Defaults to true.
    #
    # @return [true, false] true if any events were processed; otherwise false.
    def call(batch_size: 1, thread_safe: true)
      return false if processing? || event_queue.empty?

      if thread_safe
        @mutex.synchronize { process_events(batch_size:) }
      else
        process_events(batch_size:)
      end
    end

    # @return [true, false] true if the scene is processing events, otherwise
    #   false.
    def processing? = @processing

    private

    attr_reader :event_queue

    attr_reader :event_stack

    def process_events(batch_size: 1) # rubocop:disable Naming/PredicateMethod
      @processing = true
      total       = 0

      while total < batch_size
        count  = process_next_event
        total += count

        break if count.zero?
      end

      @processing = false

      !total.zero?
    end

    def process_next_event
      begin
        event = event_queue.pop(true)
      rescue ThreadError
        nil
      end

      return 0 unless event

      handle_event(event)

      count = 1

      (count += 1) && handle_event(event) while (event = event_stack.pop)

      count
    end
  end
end
