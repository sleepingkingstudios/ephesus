# frozen_string_literal: true

require 'securerandom'

require 'ephesus/core/messages'
require 'ephesus/core/messages/notification'

module Ephesus::Core::Messages
  # Message used to alert actors of a processing error.
  ErrorNotification =
    Ephesus::Core::Messages::Notification
    .define(:error, :error_id, :message, :details) do
      # @param error [Cuprum::Error] the error to report.
      # @param message [String] the error message.
      # @param original_actor [Ephesus::Core::Actor] the actor that performed
      #   the triggering action.
      # @param error_id [String] a unique identifier for the error.
      # @param current_actor [Ephesus::Core::Actor, nil] the actor handling the
      #   notification, if any.
      # @param context [Hash] additional context for the notification handler.
      # @param details [Hash] the error details
      def initialize( # rubocop:disable Metrics/ParameterLists
        error:,
        original_actor:,
        context:        {},
        current_actor:  nil,
        details:        {},
        error_id:       nil,
        message:        nil
      )
        error_id ||= SecureRandom.uuid_v7
        message  ||= error.message

        super
      end

      # @return [Hash] a JSON-compatible representating of the message.
      def as_json
        json = {
          'error'    => error.as_json,
          'error_id' => error_id,
          'message'  => message,
          'type'     => type
        }

        details.each_with_object(json) do |(key, value), hsh|
          hsh[key.to_s] = convert_to_json(value)
        end
      end
    end
end
