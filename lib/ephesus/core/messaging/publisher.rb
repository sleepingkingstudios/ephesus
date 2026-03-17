# frozen_string_literal: true

require 'ephesus/core/messaging'
require 'ephesus/core/messaging/subscription'

module Ephesus::Core::Messaging
  # Mixin providing methods for publishing messages.
  module Publisher
    # @private
    class AllChannels
      def inspect = '#<Ephesus::Core::Messaging::Publisher::AllChannels>'
    end
    private_constant :AllChannels

    # Unique constant used to refer to all message channels.
    ALL_CHANNELS = AllChannels.new.freeze

    # @overload add_subscription(subscriber, channel: :default, matching: nil, method_name: :receive_message, &block)
    #   Defines and adds a message subscription.
    #
    #   @param subscriber [Object] the object to receive messages.
    #   @param channel [Symbol] the channel to subscribe to.
    #   @param matching [#===, nil] condition used to check published messages.
    #     If the condition exists and the message does not match the condition
    #     (using the case equality operation #===), then the message will not
    #     be passed to the subscriber.
    #   @param method_name [String, Symbol] the name of the method on the
    #     subscriber that will be called with the message. Defaults to
    #     :receive_message.
    #
    #   @yield the block to call when a matching message is published. If a
    #     block is given, the configured method (if any) will not be called on
    #     the subscriber.
    #
    #   @yield_param channel [Symbol] the channel in which the message was
    #     published. This value may differ from the subscription channel for
    #     subscriptions to ALL_CHANNELS.
    #   @yield_param message [Ephesus::Core::Message] the published message.
    def add_subscription(subscriber, channel: :default, **, &block)
      subscription = Ephesus::Core::Messaging::Subscription.new(
        block:,
        channel:,
        publisher:  self,
        subscriber:,
        **
      )

      (message_channels[channel] ||= Set.new) << subscription

      subscription
    end

    # Publishes the method to all subscriptions for the given channel.
    #
    # The message will also be published to any subscriptions with channel:
    # ALL_CHANNELS. Alternatively, if the given channel is ALL_CHANNELS, then
    # the message will be published to all subscriptions.
    #
    # @param message [Ephesus::Core::Message] the message to publish.
    # @param channel [Symbol] the channel to publish in. Defaults to :default.
    #
    # @return [self]
    def publish(message, channel: :default)
      each_subscription(channel) do |subscription|
        subscription.publish(channel:, message:)
      end

      self
    end

    # @overload remove_subscription(subscription)
    #   Removes the subscription from the corresponding channel.
    #
    #   @param subscription [Ephesus::Core::Messaging::Subscription] the
    #     subscription to remove.
    #
    #   @return [Ephesus::Core::Messaging::Subscription, nil] the removed
    #     subscription, or nil if the publisher did not include the given
    #     subscription.
    #
    # @overload remove_subscription(subscriber, channel: :default)
    #   Finds and removes the matching subscription from the given channel.
    #
    #   @param subscriber [Object] the subscriber to remove.
    #   @param channel [Symbol] the channel to remove a subscription from.
    #
    #   @return [Ephesus::Core::Messaging::Subscription, nil] the removed
    #     subscription, or nil if the publisher did not have a subscription
    #     for the given subscriber and channel.
    def remove_subscription(value, channel: :default)
      if value.is_a?(Ephesus::Core::Messaging::Subscription)
        return remove_subscription_by_identity(value)
      end

      subscriptions = message_channels[channel]
      subscription  = subscriptions.find do |subscription|
        subscription.subscriber == value
      end

      subscriptions.delete(subscription) if subscription

      subscription
    end

    private

    def each_subscription(channel, &)
      return enum_for(:each_subscriber, channel) unless block_given?

      if channel == ALL_CHANNELS
        message_channels.each_value { |subscriptions| subscriptions.each(&) }
      else
        message_channels[ALL_CHANNELS].each(&)

        message_channels[channel].each(&)
      end
    end

    def message_channels
      @message_channels ||= Hash.new { |hsh, key| hsh[key] = Set.new }
    end

    def remove_subscription_by_identity(subscription)
      return unless message_channels.key?(subscription.channel)

      subscriptions = message_channels[subscription.channel]

      return unless subscriptions.include?(subscription)

      subscriptions.delete(subscription)

      subscription
    end
  end
end
