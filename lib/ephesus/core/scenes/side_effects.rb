# frozen_string_literal: true

require 'ephesus/core/scenes'
require 'ephesus/core/messaging/publisher'

module Ephesus::Core::Scenes
  # Functionality for handling side effects when calling a Scene.
  module SideEffects
    include Ephesus::Core::Messaging::Publisher

    # Exception raised when a handler is not found for a side effect.
    class UnhandledSideEffectError < StandardError; end

    private

    def handle_notify(notification) # rubocop:disable Metrics/MethodLength
      context = notification.context.merge(scene_type: type)

      if notification.current_actor
        notification
          .current_actor
          .handle_notification(notification.with(context:))
      else
        each_actor do |actor|
          actor.handle_notification(
            notification.with(current_actor: actor, context:)
          )
        end
      end
    end

    def handle_push_event(event)
      event_stack << event
    end

    def handle_side_effect(side_effect, *details)
      case side_effect
      when :notify            then handle_notify(*details)
      when :push_event        then handle_push_event(*details)
      when :subscribe         then handle_subscribe(**details.first)
      when :unsubscribe       then handle_unsubscribe(**details.first)
      when :update_connection then handle_update_connection(*details)
      else
        raise UnhandledSideEffectError,
          unhandled_side_effect_message_for(side_effect, details)
      end
    end

    def handle_subscribe(subscriber:, **)
      subscriber.subscribe(self, **)
    end

    def handle_unsubscribe(subscriber:, **)
      subscriber.unsubscribe(self, **)
    end

    def unhandled_side_effect_message_for(side_effect, details)
      details_data = details.map(&:inspect).join(', ')

      "no handler found for side effect #{side_effect.inspect} " \
        "(#{details_data})"
    end

    def handle_update_connection(actor_id, data)
      actor = state.get('actors', actor_id)

      return unless actor

      message = Ephesus::Core::Connection::UpdateConnectionMessage.new(data:)

      actor.handle_connection_update(message)
    end
  end
end
