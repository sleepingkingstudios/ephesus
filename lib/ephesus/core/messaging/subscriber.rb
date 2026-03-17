# frozen_string_literal: true

require 'ephesus/core/messaging'

module Ephesus::Core::Messaging
  # Mixin providing methods for subscribing to a message publisher.
  module Subscriber
    # Defines and adds a message subscription.
    #
    # @param publisher [Ephesus::Core::Messaging::Publisher] the object from
    #   which to receive messages.
    # @param channel [Symbol] the channel to subscribe to.
    # @param matching [#===, nil] condition used to check published messages.
    #   If the condition exists and the message does not match the condition
    #   (using the case equality operation #===), then the message will not be
    #   passed to the subscriber.
    # @param method_name [String, Symbol] the name of the method on the
    #   subscriber that will be called with the message. Defaults to
    #   :receive_message.
    def subscribe(
      publisher,
      channel:     :default,
      matching:    nil,
      method_name: nil,
      &
    )
      publisher
        .add_subscription(self, channel:, matching:, method_name:, &)
        .tap { |subscription| message_subscriptions << subscription }
    end

    # @overload unsubscribe(subscription)
    #   Removes the subscription.
    #
    #   @param subscription [Ephesus::Core::Messaging::Subscription] the
    #     subscription to remove.
    #
    #   @return [Ephesus::Core::Messaging::Subscription, nil] the removed
    #     subscription, or nil if the publisher did not include the given
    #     subscription.
    #
    # @overload remove_subscription(publisher, channel: :default)
    #   Finds and removes all subscriptions for the publisher and channel.
    #
    #   @param publisher [Ephesus::Core::Messaging::Publisher] the object from
    #     which to receive messages.
    #   @param channel [Symbol] the channel to remove a subscription from.
    #
    #   @return [Array, Ephesus::Core::Messaging::Subscription, nil] the removed
    #     subscription(s), or nil if the publisher did not have a subscription
    #     for the given subscriber and channel.
    def unsubscribe(value, channel: nil)
      if value.is_a?(Ephesus::Core::Messaging::Subscription)
        return unsubscribe_by_identity(value)
      end

      find_matching_subscriptions(channel:, publisher: value)
        .each { |subscription| unsubscribe_by_identity(subscription) }
        .then { |matching| format_matching_subscriptions(matching) }
    end

    # @overload unsubscribe()
    #   Removes all subscriptions.
    #
    #   @return [Array<Ephesus::Core::Messaging::Subscriptions>] the removed
    #     subscriptions.
    #
    # @overload unsubscribe_all(channel:)
    #   Removes all subscriptions to the given channel.
    #
    #   @param channel [Symbol] the channel from which to remove subscriptions.
    #
    #   @return [Array<Ephesus::Core::Messaging::Subscriptions>] the removed
    #     subscriptions.
    def unsubscribe_all(channel: nil)
      find_matching_subscriptions(channel:).each do |subscription|
        unsubscribe_by_identity(subscription)
      end
    end

    private

    def find_matching_subscriptions(channel:, publisher: nil)
      message_subscriptions.select do |subscription|
        next false if channel   && channel   != subscription.channel
        next false if publisher && publisher != subscription.publisher

        true
      end
    end

    def format_matching_subscriptions(matching)
      matching
        .compact
        .then { |matching| matching.empty? ? nil : matching }
        &.then { |matching| matching.size == 1 ? matching.first : matching }
    end

    def message_subscriptions
      @message_subscriptions ||= Set.new
    end

    def unsubscribe_by_identity(subscription)
      publisher = subscription.publisher

      message_subscriptions.delete(subscription)

      return subscription if publisher.remove_subscription(subscription)

      nil
    end
  end
end
