# frozen_string_literal: true

require 'ephesus/core/message'
require 'ephesus/core/messages'

module Ephesus::Core::Messages
  # Message subclass with optional :connection member.
  LazyConnectionMessage = Ephesus::Core::Message.define(:connection) do
    # @param connection [Ephesus::Core::Connection, nil] the connection for the
    #   message.
    def initialize(connection: nil, **) = super
  end
end
