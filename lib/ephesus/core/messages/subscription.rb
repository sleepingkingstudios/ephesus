# frozen_string_literal: true

require 'ephesus/core/messages'

module Ephesus::Core::Messages
  BOTH_KEYWORDS = %i[channel message].freeze
  private_constant :BOTH_KEYWORDS

  EMPTY_KEYWORDS = [].freeze
  private_constant :EMPTY_KEYWORDS

  CHANNEL_KEYWORD = %i[channel].freeze
  private_constant :CHANNEL_KEYWORD

  MESSAGE_KEYWORD = %i[message].freeze
  private_constant :MESSAGE_KEYWORD

  # Data object representing a subscription to a messages publisher.
  Subscription = Data.define(
    :block,
    :block_params,
    :channel,
    :matching,
    :method_name,
    :publisher,
    :subscriber
  ) do
    def initialize( # rubocop:disable  Metrics/ParameterLists
      channel:,
      publisher:,
      subscriber:,
      block:       nil,
      matching:    nil,
      method_name: nil
    )
      super(
        block:,
        block_params: block_params_for(block),
        channel:,
        matching:,
        method_name:,
        publisher:,
        subscriber:
      )
    end

    private :block_params

    # @return [String] a human-readable representation of the subscription.
    def inspect
      '#<Subscription ' \
        "@channel=#{channel.inspect} " \
        "@subscriber=#{subscriber.inspect}>"
    end

    # Checks if the message matches the condition, if any.
    #
    # @param message [Ephesus::Core::Message] the message to check.
    #
    # @return [true, false] true if the subscription is unconditional, or if the
    #   message matches the condition; otherwise false.
    def matches?(message)
      return true unless matching

      matching === message # rubocop:disable Style/CaseEquality
    end

    # Publishes the message to the subscriber.
    #
    # The implementation depends on the subscription configuration.
    #
    # - If a block is given, the block will be called with either the message as
    #   a positional argument (if the block does not accept keywords), or the
    #   channel and/or message as keyword parameters, depending on the keywords
    #   accepted by the block.
    # - If a method name is given, the corresponding public method on the
    #   subscriber will be called with the message as a positional argument.
    # - Otherwise, calls the #receive_message method on the subscriber with the
    #   message as a positional argument.
    #
    # @param channel [Symbol] the channel in which to publish the message.
    # @param message [Ephesus::Core::Message] the message to publish.
    #
    # @return [true, false] true if a message was published, otherwise false.
    def publish(channel:, message:) # rubocop:disable Naming/PredicateMethod
      return false unless matches?(message)

      if block
        call_block(channel:, message:)
      elsif method_name
        subscriber.public_send(method_name, message)
      else
        subscriber.receive_message(message)
      end

      true
    end

    # Removes the subscription from the publisher's subscriptions.
    def unsubscribe
      publisher.unsubscribe(self)
    end

    private

    def block_params_for(block) # rubocop:disable Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
      return unless block

      params = block.parameters

      return BOTH_KEYWORDS if params.any? { |(type, _)| type == :keyrest }

      keywords = keyword_params_for(params)
      channel  = keywords.include?(:channel)
      message  = keywords.include?(:message)

      if channel && message
        BOTH_KEYWORDS
      elsif channel
        CHANNEL_KEYWORD
      elsif message
        MESSAGE_KEYWORD
      else
        EMPTY_KEYWORDS
      end
    end

    def call_block(channel:, message:)
      return block.call(message) if block_params.empty?

      block.call(**{ channel:, message: }.slice(*block_params))
    end

    def keyword_params_for(params)
      params.each.with_object([]) do |(type, name), keywords|
        next unless type == :keyreq || type == :key # rubocop:disable Style/MultipleComparison

        keywords << name
      end
    end
  end
end
