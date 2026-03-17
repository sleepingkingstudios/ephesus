# frozen_string_literal: true

require 'ephesus/core/messages'

module Ephesus::Core::Messages
  # Message used to notify actors of a handled scene event.
  Notification =
    Ephesus::Core::Message.define(:current_actor, :original_actor, :context) do
      # @param actor [Ephesus::Core::Actor, nil] the actor handling the
      #   notification, if any.
      # @param original_actor [Ephesus::Core::Actor] the actor that performed
      #   the triggering action.
      # @param context [Hash] additional context for the notification handler.
      def initialize(original_actor:, current_actor: nil, context: {}, **)
        super
      end
    end
end
