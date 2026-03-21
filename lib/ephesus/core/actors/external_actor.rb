# frozen_string_literal: true

require 'ephesus/core/actor'
require 'ephesus/core/actors'

module Ephesus::Core::Actors
  # An external actor holds a reference to a server connection.
  class ExternalActor < Ephesus::Core::Actor
    # @param connection [Ephesus::Core::Connection] the server connection.
    def initialize(connection:)
      super()

      @connection = connection
    end

    # @return [Ephesus::Core::Connection] the server connection.
    attr_reader :connection

    # @return [Hash] a JSON-compatible representating of the actor.
    def as_json = super.merge('connection_id' => connection.id)
  end
end
