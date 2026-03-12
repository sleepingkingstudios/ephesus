# frozen_string_literal: true

require 'ephesus/core/message'
require 'ephesus/core/messages/subscription'

RSpec.describe Ephesus::Core::Messages::Subscription do
  subject(:subscription) { described_class.new(**attributes) }

  deferred_context 'when initialized with a block' do
    let(:block)      { ->(_) {} }
    let(:attributes) { super().merge(block:) }
  end

  let(:attributes) do
    {
      channel:,
      publisher:,
      subscriber:
    }
  end
  let(:channel)    { :notifications }
  let(:publisher)  { instance_double(Spec::Publisher, unsubscribe: nil) }
  let(:subscriber) { instance_double(Spec::Subscriber, receive_message: nil) }

  example_constant 'Spec::Notification' do
    Ephesus::Core::Message.define(:message)
  end

  example_class 'Spec::Publisher' do |klass|
    klass.define_method(:unsubscribe) { |_| nil }
  end

  example_class 'Spec::Subscriber' do |klass|
    klass.define_method(:receive_message) { |_| nil }
  end

  describe '.new' do
    let(:expected_keywords) do
      %i[
        block
        channel
        matching
        method_name
        publisher
        subscriber
      ]
    end

    it 'should define the constructor' do
      expect(described_class)
        .to be_constructible
        .with(0).arguments
        .and_keywords(*expected_keywords)
    end
  end

  describe '#block' do
    include_examples 'should define reader', :block, nil

    wrap_deferred 'when initialized with a block' do
      it { expect(subscription.block).to be block }
    end
  end

  describe '#channel' do
    include_examples 'should define reader', :channel, -> { channel }
  end

  describe '#inspect' do
    let(:expected) do
      '#<Subscription ' \
        "@channel=#{channel.inspect} " \
        "@subscriber=#{subscriber.inspect}>"
    end

    it { expect(subscription.inspect).to be == expected }
  end

  describe '#matches?' do
    let(:message) { Ephesus::Core::Message.new }

    it { expect(subscription).to respond_to(:matches?).with(1).argument }

    it { expect(subscription.matches?(message)).to be true }

    context 'when initialized with matching: a Module' do
      let(:matching)   { Spec::Notification }
      let(:attributes) { super().merge(matching:) }

      describe 'with a non-matching message' do
        it { expect(subscription.matches?(message)).to be false }
      end

      describe 'with a matching message' do
        let(:message) do
          Spec::Notification.new(message: 'Greetings, starfighter!')
        end

        it { expect(subscription.matches?(message)).to be true }
      end
    end

    context 'when initialized with matching: a Proc' do
      let(:matching)   { ->(message) { message.is_a?(Spec::Notification) } }
      let(:attributes) { super().merge(matching:) }

      describe 'with a non-matching message' do
        it { expect(subscription.matches?(message)).to be false }
      end

      describe 'with a matching message' do
        let(:message) do
          Spec::Notification.new(message: 'Greetings, starfighter!')
        end

        it { expect(subscription.matches?(message)).to be true }
      end
    end
  end

  describe '#matching' do
    include_examples 'should define reader', :matching, nil

    context 'when initialized with matching: a Module' do
      let(:matching)   { Spec::Notification }
      let(:attributes) { super().merge(matching:) }

      it { expect(subscription.matching).to be == matching }
    end

    context 'when initialized with matching: a Proc' do
      let(:matching)   { ->(message) { message.is_a?(Spec::Notification) } }
      let(:attributes) { super().merge(matching:) }

      it { expect(subscription.matching).to be == matching }
    end
  end

  describe '#method_name' do
    include_examples 'should define reader', :method_name, nil

    context 'when initialized with method_name: value' do
      let(:method_name) { :update }
      let(:attributes)  { super().merge(method_name:) }

      it { expect(subscription.method_name).to be method_name }
    end
  end

  describe '#publish' do
    deferred_examples 'should publish matching messages' do
      it { expect(subscription.publish(channel:, message:)).to be true }

      include_deferred 'should publish the message'

      context 'when initialized with matching: value' do
        let(:matching)   { Spec::Notification }
        let(:attributes) { super().merge(matching:) }

        describe 'with a non-matching message' do
          it { expect(subscription.publish(channel:, message:)).to be false }

          include_deferred 'should not publish the message'
        end

        describe 'with a matching message' do
          let(:message) do
            Spec::Notification.new(message: 'Greetings, starfighter!')
          end

          it { expect(subscription.publish(channel:, message:)).to be true }

          include_deferred 'should publish the message'
        end
      end
    end

    let(:channel) { :notifications }
    let(:message) { Ephesus::Core::Message.new }

    it 'should define the method' do
      expect(subscription)
        .to respond_to(:publish)
        .with(0).arguments
        .and_keywords(:channel, :message)
    end

    context 'with default parameters' do
      deferred_examples 'should not publish the message' do
        it 'should not pass the message to #receive_message' do
          subscription.publish(channel:, message:)

          expect(subscriber).not_to have_received(:receive_message)
        end
      end

      deferred_examples 'should publish the message' do
        it 'should pass the message to #receive_message' do
          subscription.publish(channel:, message:)

          expect(subscriber).to have_received(:receive_message).with(message)
        end
      end

      include_deferred 'should publish matching messages'
    end

    wrap_deferred 'when initialized with a block' do
      deferred_examples 'should not publish the message' do
        it 'should not call the block' do
          subscription.publish(channel:, message:)

          expect(received_parameters.value).to be nil
        end
      end

      deferred_examples 'should publish the message' do
        it 'should call the block' do
          subscription.publish(channel:, message:)

          expect(received_parameters.value).to be == expected_parameters
        end
      end

      let(:received_parameters) { Struct.new(:value).new }

      context 'when the block takes one parameter' do
        let(:block) do
          ->(message) { received_parameters.value = { message: } }
        end
        let(:expected_parameters) { { message: } }

        include_deferred 'should publish matching messages'
      end

      context 'when the block takes a :channel keyword' do
        let(:block) do
          ->(channel:) { received_parameters.value = { channel: } }
        end
        let(:expected_parameters) { { channel: } }

        include_deferred 'should publish matching messages'
      end

      context 'when the block takes a :message keyword' do
        let(:block) do
          ->(message:) { received_parameters.value = { message: } }
        end
        let(:expected_parameters) { { message: } }

        include_deferred 'should publish matching messages'
      end

      context 'when the block takes :channel and :message keywords' do
        let(:block) do
          lambda do |channel:, message:|
            received_parameters.value = { channel:, message: }
          end
        end
        let(:expected_parameters) { { channel:, message: } }

        include_deferred 'should publish matching messages'
      end
    end

    context 'when initialized with method_name: value' do
      deferred_examples 'should not publish the message' do
        it 'should not pass the message to the specified method' do
          subscription.publish(channel:, message:)

          expect(subscriber).not_to have_received(method_name)
        end
      end

      deferred_examples 'should publish the message' do
        it 'should pass the message to the specified method' do
          subscription.publish(channel:, message:)

          expect(subscriber).to have_received(method_name).with(message)
        end
      end

      let(:method_name) { :update }
      let(:attributes)  { super().merge(method_name:) }

      before(:example) do
        Spec::Subscriber.define_method(:update) { |_| nil }

        allow(subscriber).to receive(:update)
      end

      include_deferred 'should publish matching messages'
    end
  end

  describe '#publisher' do
    include_examples 'should define reader', :publisher, -> { publisher }
  end

  describe '#subscriber' do
    include_examples 'should define reader', :subscriber, -> { subscriber }
  end

  describe '#unsubscribe' do
    it { expect(subscription).to respond_to(:unsubscribe).with(0).arguments }

    it 'should delegate to the publisher' do
      subscription.unsubscribe

      expect(publisher)
        .to have_received(:unsubscribe)
        .with(subscription)
    end
  end
end
