# frozen_string_literal: true

require 'ephesus/core/messages/publisher'

RSpec.describe Ephesus::Core::Messages::Publisher do
  subject(:publisher) { described_class.new }

  deferred_context 'when the publisher has many subscriptions' do
    let(:published_messages) { Hash.new { |hsh, key| hsh[key] = [] } }
    let(:default_subscriber) do
      instance_double(
        Spec::Subscriber,
        inspect:         'default_subscriber',
        receive_message: nil
      )
    end
    let(:notifications_subscriber) do
      instance_double(
        Spec::Subscriber,
        inspect:         'notifications_subscriber',
        receive_message: nil
      )
    end
    let(:multichannel_subscriber) do
      instance_double(
        Spec::Subscriber,
        inspect:         'multichannel_subscriber',
        receive_message: nil
      )
    end
    let(:omnichannel_subscriber) do
      instance_double(
        Spec::Subscriber,
        inspect:         'omnichannel_subscriber',
        receive_message: nil
      )
    end

    before(:example) do
      publisher.add_subscription(default_subscriber) do |channel:, message:|
        published_messages[default_subscriber] << { channel:, message: }
      end

      publisher.add_subscription(
        notifications_subscriber,
        channel: :notifications
      ) do |channel:, message:|
        published_messages[notifications_subscriber] << { channel:, message: }
      end

      publisher.add_subscription(
        multichannel_subscriber,
        channel: :events
      ) do |channel:, message:|
        published_messages[multichannel_subscriber] << { channel:, message: }
      end

      publisher.add_subscription(
        multichannel_subscriber,
        channel: :notifications
      ) do |channel:, message:|
        published_messages[multichannel_subscriber] << { channel:, message: }
      end

      publisher.add_subscription(
        omnichannel_subscriber,
        channel: described_class::ALL_CHANNELS
      ) do |channel:, message:|
        published_messages[omnichannel_subscriber] << { channel:, message: }
      end
    end
  end

  let(:described_class) { Spec::Publisher }

  example_constant 'Spec::Notification' do
    Ephesus::Core::Message.define(:message)
  end

  example_class 'Spec::Publisher' do |klass|
    klass.include Ephesus::Core::Messages::Publisher # rubocop:disable RSpec/DescribedClass
  end

  example_class 'Spec::Subscriber' do |klass|
    klass.define_method(:receive_message) { |_| nil }
  end

  describe '::ALL_CHANNELS' do
    let(:expected) do
      '#<Ephesus::Core::Messages::Publisher::AllChannels>'
    end

    include_examples 'should define constant', :ALL_CHANNELS

    it { expect(described_class::ALL_CHANNELS.inspect).to be == expected }
  end

  describe '#add_subscription' do
    let(:expected_keywords) do
      %i[
        channel
        matching
        method_name
      ]
    end
    let(:subscriber) { instance_double(Spec::Subscriber, receive_message: nil) }
    let(:channel)    { :default }
    let(:options)    { {} }
    let(:block)      { nil }
    let(:expected) do
      Ephesus::Core::Messages::Subscription.new(
        block:,
        channel:,
        publisher:,
        subscriber:,
        **options
      )
    end

    define_method(:add_subscription) do
      publisher.add_subscription(subscriber, **options, &block)
    end

    define_method(:channel_subscriptions) do
      publisher.send(:message_channels)[channel]
    end

    it 'should define the method' do
      expect(publisher)
        .to respond_to(:add_subscription)
        .with(1).argument
        .and_keywords(*expected_keywords)
        .and_a_block
    end

    it { expect(add_subscription).to be == expected }

    it 'should add the subscription for the channel', :aggregate_failures do
      subscription = nil

      expect { subscription = add_subscription }.to(
        change { channel_subscriptions.count }.by(1) # rubocop:disable RSpec/ExpectChange
      )
      expect(channel_subscriptions).to include subscription
    end

    describe 'with a block' do
      let(:block) { ->(_) {} }

      it { expect(add_subscription).to be == expected }
    end

    describe 'with channel: ALL_CHANNELS' do
      let(:channel) { described_class::ALL_CHANNELS }
      let(:options) { super().merge(channel:) }

      it { expect(add_subscription).to be == expected }
    end

    describe 'with channel: name' do
      let(:channel) { :notifications }
      let(:options) { super().merge(channel:) }

      it { expect(add_subscription).to be == expected }
    end

    describe 'with matching: value' do
      let(:matching) { Spec::Notification }
      let(:options)  { super().merge(matching:) }

      it { expect(add_subscription).to be == expected }
    end

    describe 'with method_name: value' do
      let(:method_name) { :update }
      let(:options)     { super().merge(method_name:) }

      it { expect(add_subscription).to be == expected }
    end

    wrap_deferred 'when the publisher has many subscriptions' do
      it { expect(add_subscription).to be == expected }

      it 'should add the subscription for the channel', :aggregate_failures do
        subscription = nil

        expect { subscription = add_subscription }.to(
          change { channel_subscriptions.count }.by(1) # rubocop:disable RSpec/ExpectChange
        )
        expect(channel_subscriptions).to include subscription
      end
    end
  end

  describe '#message_channels' do
    include_examples 'should define private reader', :message_channels, {}
  end

  describe '#publish' do
    let(:message) { Ephesus::Core::Message.new }

    it 'should define the method' do
      expect(publisher)
        .to respond_to(:publish)
        .with(1).argument
        .and_keywords(:channel)
    end

    it { expect(publisher.publish(message)).to be publisher }

    describe 'with channel: value' do
      let(:channel) { :notifications }

      it { expect(publisher.publish(message, channel:)).to be publisher }
    end

    wrap_deferred 'when the publisher has many subscriptions' do
      let(:channel) { :default }
      let(:expected_messages) do
        {
          default_subscriber     => [{ channel:, message: }],
          omnichannel_subscriber => [{ channel:, message: }]
        }
      end

      it 'should publish the message to matching subscriptions' do
        publisher.publish(message)

        expect(published_messages).to match expected_messages
      end

      describe 'with channel: value' do
        let(:channel) { :notifications }
        let(:expected_messages) do
          {
            notifications_subscriber => [{ channel:, message: }],
            multichannel_subscriber  => [{ channel:, message: }],
            omnichannel_subscriber   => [{ channel:, message: }]
          }
        end

        it 'should publish the message to matching subscriptions' do
          publisher.publish(message, channel:)

          expect(published_messages).to match expected_messages
        end
      end

      describe 'with channel: ALL_CHANNELS' do
        let(:channel) { described_class::ALL_CHANNELS }
        let(:expected_messages) do
          {
            default_subscriber       => [{ channel:, message: }],
            notifications_subscriber => [{ channel:, message: }],
            multichannel_subscriber  => [
              { channel:, message: },
              { channel:, message: }
            ],
            omnichannel_subscriber   => [{ channel:, message: }]
          }
        end

        it 'should publish the message to matching subscriptions' do
          publisher.publish(message, channel:)

          expect(published_messages).to match expected_messages
        end
      end
    end
  end

  describe '#remove_subscription' do
    define_method(:channel_subscriptions) do
      publisher.send(:message_channels)[channel]
    end

    it 'should define the method' do
      expect(publisher)
        .to respond_to(:remove_subscription)
        .with(1).argument
        .and_keywords(:channel)
    end

    describe 'with a subscriber' do
      let(:subscriber) { Spec::Subscriber.new }
      let(:channel)    { :default }
      let(:options)    { {} }

      define_method(:remove_subscription) do
        publisher.remove_subscription(subscriber)
      end

      it { expect(remove_subscription).to be nil }

      it 'should not change the channel subscriptions' do
        expect { remove_subscription }.not_to(
          change { channel_subscriptions }
        )
      end

      describe 'with channel: value' do
        let(:channel) { :notifications }
        let(:options) { super().merge(channel:) }

        it { expect(remove_subscription).to be nil }

        it 'should not change the channel subscriptions' do
          expect { remove_subscription }.not_to(
            change { channel_subscriptions }
          )
        end
      end
    end

    describe 'with a subscription' do
      let(:subscription) do
        Ephesus::Core::Messages::Subscription.new(
          channel:    :default,
          publisher:  described_class.new,
          subscriber: Spec::Subscriber.new
        )
      end
      let(:channel) { subscription.channel }

      define_method(:remove_subscription) do
        publisher.remove_subscription(subscription)
      end

      it { expect(remove_subscription).to be nil }

      it 'should not change the channel subscriptions' do
        expect { remove_subscription }.not_to(
          change { channel_subscriptions }
        )
      end
    end

    wrap_deferred 'when the publisher has many subscriptions' do
      describe 'with a subscriber' do
        let(:channel) { :default }
        let(:options) { {} }

        define_method(:remove_subscription) do
          publisher.remove_subscription(subscriber, **options)
        end

        context 'when the publisher does not have a matching subscription' do
          let(:subscriber) { Spec::Subscriber.new }

          it { expect(remove_subscription).to be nil }

          it 'should not change the channel subscriptions' do
            expect { remove_subscription }.not_to(
              change { channel_subscriptions }
            )
          end
        end

        context 'when the subscription is for a different channel' do
          let(:subscriber) { notifications_subscriber }

          it { expect(remove_subscription).to be nil }

          it 'should not change the channel subscriptions' do
            expect { remove_subscription }.not_to(
              change { channel_subscriptions }
            )
          end
        end

        context 'when the publisher has a matching subscription' do
          let(:subscriber) { default_subscriber }
          let!(:subscription) do
            channel_subscriptions.find do |subscription|
              subscription.subscriber == subscriber
            end
          end

          it { expect(remove_subscription).to be subscription }

          it 'should remove the subscription from the channel',
            :aggregate_failures \
          do
            expect { remove_subscription }.to(
              change { channel_subscriptions.count }.by(-1) # rubocop:disable RSpec/ExpectChange
            )
            expect(channel_subscriptions).not_to include subscription
          end
        end

        # rubocop:disable RSpec/NestedGroups
        describe 'with channel: value' do
          let(:channel) { :notifications }
          let(:options) { super().merge(channel:) }

          context 'when the publisher does not have a matching subscription' do
            let(:subscriber) { Spec::Subscriber.new }

            it { expect(remove_subscription).to be nil }

            it 'should not change the channel subscriptions' do
              expect { remove_subscription }.not_to(
                change { channel_subscriptions }
              )
            end
          end

          context 'when the subscription is for a different channel' do
            let(:subscriber) { notifications_subscriber }
            let(:options)    { super().merge(channel: :events) }

            it { expect(remove_subscription).to be nil }

            it 'should not change the channel subscriptions' do
              expect { remove_subscription }.not_to(
                change { channel_subscriptions }
              )
            end
          end

          context 'when the publisher has a matching subscription' do
            let(:subscriber) { notifications_subscriber }
            let!(:subscription) do
              channel_subscriptions.find do |subscription|
                subscription.subscriber == subscriber
              end
            end

            it { expect(remove_subscription).to be subscription }

            it 'should remove the subscription from the channel',
              :aggregate_failures \
            do
              expect { remove_subscription }.to(
                change { channel_subscriptions.count }.by(-1) # rubocop:disable RSpec/ExpectChange
              )
              expect(channel_subscriptions).not_to include subscription
            end
          end
        end
        # rubocop:enable RSpec/NestedGroups
      end

      describe 'with a subscription' do
        define_method(:remove_subscription) do
          publisher.remove_subscription(subscription)
        end

        context 'when the publisher does not include the subscription' do
          let(:subscription) do
            Ephesus::Core::Messages::Subscription.new(
              channel:    :default,
              publisher:  described_class.new,
              subscriber: Spec::Subscriber.new
            )
          end
          let(:channel) { subscription.channel }

          it { expect(remove_subscription).to be nil }

          it 'should not change the channel subscriptions' do
            expect { remove_subscription }.not_to(
              change { channel_subscriptions }
            )
          end
        end

        context 'when the publisher includes the subscription' do
          let(:channel) { :notifications }
          let(:subscription) do
            channel_subscriptions.find do |subscription|
              subscription.subscriber == notifications_subscriber
            end
          end

          it { expect(remove_subscription).to be subscription }

          it 'should remove the subscription from the channel',
            :aggregate_failures \
          do
            expect { remove_subscription }.to(
              change { channel_subscriptions.count }.by(-1) # rubocop:disable RSpec/ExpectChange
            )
            expect(channel_subscriptions).not_to include subscription
          end
        end
      end
    end
  end
end
