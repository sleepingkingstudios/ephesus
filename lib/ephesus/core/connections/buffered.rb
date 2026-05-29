# frozen_string_literal: true

require 'ephesus/core/connections'

module Ephesus::Core::Connections
  # Extends a connection to capture output events in a thread-safe buffer.
  module Buffered
    def initialize(**)
      super

      @output_buffer = Thread::Queue.new

      subscribe(self, channel: :output) do |message|
        @output_buffer.enq(message)
      end
    end

    # @return [true, false] true if there are no messages in the output buffer,
    #   otherwise false.
    def empty_buffer? = @output_buffer.empty?

    # Empties and returns the contents of the output buffer.
    #
    # @return [Array<Ephesus::Core::Message>] the buffered messages.
    def flush_buffer
      messages = []

      loop do
        messages << @output_buffer.deq(true)
      rescue ThreadError
        break
      end

      messages
    end
  end
end
