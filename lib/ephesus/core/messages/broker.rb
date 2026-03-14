# frozen_string_literal: true

require 'ephesus/core/messages'
require 'ephesus/core/messages/publisher'
require 'ephesus/core/messages/subscriber'

module Ephesus::Core::Messages
  # Utility class for subscribing to, publishing, and republishing messages.
  class Broker
    include Ephesus::Core::Messages::Publisher
    include Ephesus::Core::Messages::Subscriber

    # Subscribes to the publisher and republishes matching messages.
    #
    # @param publisher [Ephesus::Core::Messages::Publisher] the object from
    #   which to receive messages.
    # @param channel [Symbol] the channel to subscribe to.
    # @param matching [#===, nil] condition used to check published messages.
    #   If the condition exists and the message does not match the condition
    #   (using the case equality operation #===), then the message will not be
    #   republished.
    #
    # @return [Ephesus::Core::Messages::Subscription] the generated
    #   subscription.
    def republish(publisher, channel: ALL_CHANNELS, matching: nil)
      subscribe(publisher, channel:, matching:) do |channel:, message:|
        publish(message, channel:)
      end
    end
  end
end
