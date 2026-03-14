# frozen_string_literal: true

require 'ephesus/core/messages/broker'
require 'ephesus/core/rspec/deferred/messages_examples'

RSpec.describe Ephesus::Core::Messages::Broker do
  include Ephesus::Core::RSpec::Deferred::MessagesExamples

  subject(:broker) { described_class.new }

  example_class 'Spec::Publisher' do |klass|
    klass.include Ephesus::Core::Messages::Publisher
  end

  example_class 'Spec::Subscriber' do |klass|
    klass.include Ephesus::Core::Messages::Subscriber

    klass.define_method(:receive_message) { |_| nil }
  end

  include_deferred 'should publish messages'

  include_deferred 'should subscribe to messages'

  describe '#republish' do
    let(:publisher) { Spec::Publisher.new }
    let(:channel)   { described_class::ALL_CHANNELS }
    let(:matching)  { nil }
    let(:options)   { {} }
    let(:expected) do
      {
        block:       an_instance_of(Proc),
        channel:,
        matching:,
        method_name: nil,
        publisher:,
        subscriber:  broker
      }
    end

    define_method(:message_subscriptions) do
      broker.send(:message_subscriptions)
    end

    define_method(:republish) do
      broker.republish(publisher, **options)
    end

    it 'should define the method' do
      expect(broker)
        .to respond_to(:republish)
        .with(1).argument
        .and_keywords(:channel, :matching)
    end

    it 'should return a subscription' do
      expect(republish)
        .to be_a(Ephesus::Core::Messages::Subscription)
        .and(have_attributes(expected))
    end

    it 'should add the subscription', :aggregate_failures do
      subscription = nil

      expect { subscription = republish }.to(
        change { message_subscriptions.count }.by(1) # rubocop:disable RSpec/ExpectChange
      )
      expect(message_subscriptions).to include subscription
    end

    context 'when the publisher publishes a matching message' do
      let(:message)  { Ephesus::Core::Message.new }
      let(:messages) { [] }
      let(:expected) { [{ channel: :default, message: }] }

      before(:example) do
        broker.add_subscription(self) do |channel:, message:|
          messages << { channel:, message: }
        end
      end

      it 'should republish the message' do
        republish

        publisher.publish(message)

        expect(messages).to be == expected
      end
    end

    describe 'with channel: value' do
      let(:channel) { :notifications }
      let(:options) { { channel: } }

      it 'should return a subscription' do
        expect(republish)
          .to be_a(Ephesus::Core::Messages::Subscription)
          .and(have_attributes(expected))
      end

      context 'when the publisher publishes a non-matching message' do
        let(:message)  { Ephesus::Core::Message.new }
        let(:messages) { [] }

        before(:example) do
          broker.add_subscription(self) do |channel:, message:|
            # :nocov:
            messages << { channel:, message: }
            # :nocov:
          end
        end

        it 'should not republish the message' do
          republish

          publisher.publish(message)

          expect(messages).to be == []
        end
      end

      context 'when the publisher publishes a matching message' do
        let(:message)  { Ephesus::Core::Message.new }
        let(:messages) { [] }
        let(:expected) { [{ channel: :notifications, message: }] }

        before(:example) do
          broker.add_subscription(self, channel:) do |channel:, message:|
            messages << { channel:, message: }
          end
        end

        it 'should republish the message' do
          republish

          publisher.publish(message, channel: :notifications)

          expect(messages).to be == expected
        end
      end
    end

    describe 'with matching: value' do
      let(:matching) { Spec::Notification }
      let(:options)  { super().merge(matching:) }

      example_constant 'Spec::Notification' do
        Ephesus::Core::Message.define(:message)
      end

      it 'should return a subscription' do
        expect(republish)
          .to be_a(Ephesus::Core::Messages::Subscription)
          .and(have_attributes(expected))
      end

      context 'when the publisher publishes a non-matching message' do
        let(:message)  { Ephesus::Core::Message.new }
        let(:messages) { [] }

        before(:example) do
          broker.add_subscription(self) do |channel:, message:|
            # :nocov:
            messages << { channel:, message: }
            # :nocov:
          end
        end

        it 'should not republish the message' do
          republish

          publisher.publish(message)

          expect(messages).to be == []
        end
      end

      context 'when the publisher publishes a matching message' do
        let(:message) do
          Spec::Notification.new(message: 'Greetings, starfighter!')
        end
        let(:messages) { [] }
        let(:expected) { [{ channel: :default, message: }] }

        before(:example) do
          broker.add_subscription(self, channel:) do |channel:, message:|
            messages << { channel:, message: }
          end
        end

        it 'should republish the message' do
          republish

          publisher.publish(message)

          expect(messages).to be == expected
        end
      end
    end
  end
end
