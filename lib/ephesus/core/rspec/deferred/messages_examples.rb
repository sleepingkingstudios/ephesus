# frozen_string_literal: true

require 'rspec/sleeping_king_studios/deferred'

require 'ephesus/core/rspec/deferred'

module Ephesus::Core::RSpec::Deferred
  # Deferred examples for testing publishing and subscribing to messages.
  module MessagesExamples
    include RSpec::SleepingKingStudios::Deferred::Provider

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
        subject.add_subscription(default_subscriber) do |channel:, message:|
          published_messages[default_subscriber] << { channel:, message: }
        end

        subject.add_subscription(
          notifications_subscriber,
          channel: :notifications
        ) do |channel:, message:|
          published_messages[notifications_subscriber] << { channel:, message: }
        end

        subject.add_subscription(
          multichannel_subscriber,
          channel: :events
        ) do |channel:, message:|
          published_messages[multichannel_subscriber] << { channel:, message: }
        end

        subject.add_subscription(
          multichannel_subscriber,
          channel: :notifications
        ) do |channel:, message:|
          published_messages[multichannel_subscriber] << { channel:, message: }
        end

        subject.add_subscription(
          omnichannel_subscriber,
          channel: described_class::ALL_CHANNELS
        ) do |channel:, message:|
          published_messages[omnichannel_subscriber] << { channel:, message: }
        end
      end
    end

    deferred_context 'when the subscriber has many subscriptions' do
      let(:default_publisher) do
        instance_double(
          Spec::Publisher,
          inspect:             'default_publisher',
          add_subscription:    nil,
          remove_subscription: nil
        )
          .tap { |publisher| stub_subscription(publisher) }
      end
      let(:events_publisher) do
        instance_double(
          Spec::Publisher,
          inspect:             'events_publisher',
          add_subscription:    nil,
          remove_subscription: nil
        )
          .tap { |publisher| stub_subscription(publisher) }
      end
      let(:notifications_publisher) do
        instance_double(
          Spec::Publisher,
          inspect:             'notifications_publisher',
          add_subscription:    nil,
          remove_subscription: nil
        )
          .tap { |publisher| stub_subscription(publisher) }
      end
      let(:omni_publisher) do
        instance_double(
          Spec::Publisher,
          inspect:             'omni_publisher',
          add_subscription:    nil,
          remove_subscription: nil
        )
          .tap { |publisher| stub_subscription(publisher) }
      end

      define_method :stub_subscription do |publisher| # rubocop:disable Metrics/MethodLength
        allow(publisher).to receive(:add_subscription) do |channel:, **|
          instance_double(
            Ephesus::Core::Messages::Subscription,
            channel:,
            publisher:
          ).tap do |double|
            allow(double).to receive(:is_a?) do |expected|
              expected == Ephesus::Core::Messages::Subscription
            end
          end
        end
      end

      before(:example) do
        subject.subscribe(default_publisher)
        subject.subscribe(
          events_publisher,
          channel: :events
        )
        subject.subscribe(
          notifications_publisher,
          channel: :notifications
        )
        subject.subscribe(omni_publisher)
        subject.subscribe(
          omni_publisher,
          channel: :events
        )
        subject.subscribe(
          omni_publisher,
          channel: :notifications
        )
      end
    end

    deferred_examples 'should publish messages' do
      describe '#add_subscription' do
        let(:expected_keywords) do
          %i[
            channel
            matching
            method_name
          ]
        end
        let(:subscriber) do
          instance_double(Spec::Subscriber, receive_message: nil)
        end
        let(:channel) { :default }
        let(:options) { {} }
        let(:block)   { nil }
        let(:expected) do
          Ephesus::Core::Messages::Subscription.new(
            block:,
            channel:,
            publisher:  subject,
            subscriber:,
            **options
          )
        end

        define_method(:add_subscription) do
          subject.add_subscription(subscriber, **options, &block)
        end

        define_method(:channel_subscriptions) do
          subject.send(:message_channels)[channel]
        end

        it 'should define the method' do
          expect(subject)
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

          example_constant 'Spec::Notification' do
            Ephesus::Core::Message.define(:message)
          end

          it { expect(add_subscription).to be == expected }
        end

        describe 'with method_name: value' do
          let(:method_name) { :update }
          let(:options)     { super().merge(method_name:) }

          it { expect(add_subscription).to be == expected }
        end

        wrap_deferred 'when the publisher has many subscriptions' do
          it { expect(add_subscription).to be == expected }

          it 'should add the subscription for the channel',
            :aggregate_failures \
          do
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
          expect(subject)
            .to respond_to(:publish)
            .with(1).argument
            .and_keywords(:channel)
        end

        it { expect(subject.publish(message)).to be subject }

        describe 'with channel: value' do
          let(:channel) { :notifications }

          it { expect(subject.publish(message, channel:)).to be subject }
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
            subject.publish(message)

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
              subject.publish(message, channel:)

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
              subject.publish(message, channel:)

              expect(published_messages).to match expected_messages
            end
          end
        end
      end

      describe '#remove_subscription' do
        define_method(:channel_subscriptions) do
          subject.send(:message_channels)[channel]
        end

        it 'should define the method' do
          expect(subject)
            .to respond_to(:remove_subscription)
            .with(1).argument
            .and_keywords(:channel)
        end

        describe 'with a subscriber' do
          let(:subscriber) { Spec::Subscriber.new }
          let(:channel)    { :default }
          let(:options)    { {} }

          define_method(:remove_subscription) do
            subject.remove_subscription(subscriber)
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
            subject.remove_subscription(subscription)
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
              subject.remove_subscription(subscriber, **options)
            end

            context 'when the publisher does not have a matching subscription' \
            do
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

            describe 'with channel: value' do
              let(:channel) { :notifications }
              let(:options) { super().merge(channel:) }

              context 'when the publisher does not have the subscription' do
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
          end

          describe 'with a subscription' do
            define_method(:remove_subscription) do
              subject.remove_subscription(subscription)
            end

            context 'when the publisher does not include the subscription' do
              let(:subscription) do
                Ephesus::Core::Messages::Subscription.new(
                  channel:    :default,
                  publisher:  subject.class.new,
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

    deferred_examples 'should subscribe to messages' do
      describe '#message_subscriptions' do
        include_examples 'should define private reader',
          :message_subscriptions,
          Set.new
      end

      describe '#subscribe' do
        let(:publisher) { Spec::Publisher.new }
        let(:channel)   { :default }
        let(:options)   { {} }
        let(:block)     { nil }
        let(:expected) do
          Ephesus::Core::Messages::Subscription.new(
            block:,
            channel:,
            publisher:,
            subscriber: subject,
            **options
          )
        end

        define_method(:add_subscription) do
          subject.subscribe(publisher, **options, &block)
        end

        define_method(:message_subscriptions) do
          subject.send(:message_subscriptions)
        end

        it 'should define the method' do
          expect(subject)
            .to respond_to(:subscribe)
            .with(1).argument
            .and_keywords(:channel, :matching, :method_name)
            .and_a_block
        end

        it { expect(add_subscription).to be == expected }

        it 'should add the subscription', :aggregate_failures do
          subscription = nil

          expect { subscription = add_subscription }.to(
            change { message_subscriptions.count }.by(1) # rubocop:disable RSpec/ExpectChange
          )
          expect(message_subscriptions).to include subscription
        end

        describe 'with a block' do
          let(:block) { ->(_) {} }

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

          example_constant 'Spec::Notification' do
            Ephesus::Core::Message.define(:message)
          end

          it { expect(add_subscription).to be == expected }
        end

        describe 'with method_name: value' do
          let(:method_name) { :update }
          let(:options)     { super().merge(method_name:) }

          it { expect(add_subscription).to be == expected }
        end
      end

      describe '#unsubscribe' do
        let(:matching_subscriptions) { nil }
        let(:publisher) do
          instance_double(Spec::Publisher, remove_subscription: nil)
        end

        before(:example) do
          allow(publisher).to receive(:remove_subscription) do |*, **|
            matching_subscriptions
          end
        end

        define_method(:message_subscriptions) do
          subject.send(:message_subscriptions)
        end

        it 'should define the method' do
          expect(subject)
            .to respond_to(:unsubscribe)
            .with(1).argument
            .and_keywords(:channel)
        end

        describe 'with a publisher' do
          let(:options) { {} }

          define_method(:remove_subscription) do
            subject.unsubscribe(publisher, **options)
          end

          it { expect(remove_subscription).to be nil }

          it 'should not delegate to #remove_subscription' do
            remove_subscription

            expect(publisher).not_to have_received(:remove_subscription)
          end

          describe 'with channel: value' do
            let(:channel) { :notifications }
            let(:options) { super().merge(channel:) }

            it { expect(remove_subscription).to be nil }

            it 'should not delegate to #remove_subscription' do
              remove_subscription

              expect(publisher).not_to have_received(:remove_subscription)
            end
          end
        end

        describe 'with a subscription' do
          let(:subscription) do
            Ephesus::Core::Messages::Subscription.new(
              channel:    :default,
              publisher:,
              subscriber: subject
            )
          end

          define_method(:remove_subscription) do
            subject.unsubscribe(subscription)
          end

          it { expect(remove_subscription).to be nil }

          it 'should delegate to #remove_subscription' do
            remove_subscription

            expect(publisher)
              .to have_received(:remove_subscription)
              .with(subscription)
          end

          context 'when the publisher included the subscription' do
            let(:matching_subscriptions) { subscription }

            it { expect(remove_subscription).to be subscription }
          end
        end

        wrap_deferred 'when the subscriber has many subscriptions' do
          describe 'with a publisher' do
            let(:options) { {} }

            define_method(:remove_subscription) do
              subject.unsubscribe(publisher, **options)
            end

            context 'when the subscriber does not subscribe to the publisher' do
              it { expect(remove_subscription).to be nil }

              it 'should not remove a subscription' do
                expect { remove_subscription }.not_to(
                  change { message_subscriptions }
                )
              end

              it 'should not delegate to #remove_subscription' do
                remove_subscription

                expect(publisher).not_to have_received(:remove_subscription)
              end

              describe 'with channel: value' do
                let(:channel) { :notifications }
                let(:options) { super().merge(channel:) }

                it { expect(remove_subscription).to be nil }

                it 'should not remove a subscription' do
                  expect { remove_subscription }.not_to(
                    change { message_subscriptions }
                  )
                end

                it 'should not delegate to #remove_subscription' do
                  remove_subscription

                  expect(publisher).not_to have_received(:remove_subscription)
                end
              end
            end

            context 'when the subscriber subscribes to the publisher' do
              let(:publisher) { omni_publisher }
              let!(:matching_subscriptions) do
                message_subscriptions.select do |subscription|
                  subscription.publisher == publisher
                end
              end

              it { expect(remove_subscription).to be == matching_subscriptions }

              it 'should remove the subscriptions', :aggregate_failures do # rubocop:disable RSpec/ExampleLength
                expect { remove_subscription }.to(
                  change { message_subscriptions.count }.by(-3) # rubocop:disable RSpec/ExpectChange
                )

                matching_subscriptions.each do |subscription|
                  expect(message_subscriptions).not_to include subscription
                end
              end

              it 'should delegate to #remove_subscription', # rubocop:disable RSpec/ExampleLength
                :aggregate_failures \
              do
                remove_subscription

                matching_subscriptions.each do |subscription|
                  expect(publisher)
                    .to have_received(:remove_subscription)
                    .with(subscription)
                end
              end

              describe 'with channel: value' do
                let(:channel) { :notifications }
                let(:options) { super().merge(channel:) }
                let!(:matching_subscriptions) do
                  super().select do |subscription|
                    subscription.channel == channel
                  end
                end
                let!(:matching_subscription) { matching_subscriptions.first }

                it 'should return the matching subscription' do
                  expect(remove_subscription).to be == matching_subscription
                end

                it 'should remove the subscription', :aggregate_failures do
                  expect { remove_subscription }.to(
                    change { message_subscriptions.count }.by(-1) # rubocop:disable RSpec/ExpectChange
                  )

                  expect(message_subscriptions)
                    .not_to include matching_subscription
                end

                it 'should delegate to #remove_subscription' do
                  remove_subscription

                  expect(publisher)
                    .to have_received(:remove_subscription)
                    .with(matching_subscription)
                end
              end
            end
          end

          describe 'with a subscription' do
            define_method(:remove_subscription) do
              subject.unsubscribe(subscription)
            end

            context 'when the subscriber does not include the subscription' do
              let(:subscription) do
                Ephesus::Core::Messages::Subscription.new(
                  channel:    :default,
                  publisher:,
                  subscriber: subject
                )
              end

              it { expect(remove_subscription).to be nil }

              it 'should delegate to #remove_subscription' do
                remove_subscription

                expect(publisher)
                  .to have_received(:remove_subscription)
                  .with(subscription)
              end

              context 'when the publisher included the subscription' do
                let(:matching_subscriptions) { subscription }

                it { expect(remove_subscription).to be subscription }
              end
            end

            context 'when the subscriber includes the subscription' do
              let(:publisher) { omni_publisher }
              let(:subscription) do
                message_subscriptions.find do |subscription|
                  subscription.channel == :notifications &&
                    subscription.publisher == publisher
                end
              end

              it { expect(remove_subscription).to be nil }

              it 'should remove the subscription', :aggregate_failures do
                expect { remove_subscription }.to(
                  change { message_subscriptions.count }.by(-1) # rubocop:disable RSpec/ExpectChange
                )

                expect(message_subscriptions).not_to include subscription
              end

              it 'should delegate to #remove_subscription' do
                remove_subscription

                expect(publisher)
                  .to have_received(:remove_subscription)
                  .with(subscription)
              end

              context 'when the publisher included the subscription' do
                let(:matching_subscriptions) { subscription }

                it { expect(remove_subscription).to be subscription }

                it 'should remove the subscription', :aggregate_failures do
                  expect { remove_subscription }.to(
                    change { message_subscriptions.count }.by(-1) # rubocop:disable RSpec/ExpectChange
                  )

                  expect(message_subscriptions).not_to include subscription
                end
              end
            end
          end
        end
      end

      describe '#unsubscribe_all' do
        define_method(:message_subscriptions) do
          subject.send(:message_subscriptions)
        end

        it 'should define the method' do
          expect(subject)
            .to respond_to(:unsubscribe_all)
            .with(0).arguments
            .and_keywords(:channel)
        end

        it { expect(subject.unsubscribe_all).to be == [] }

        describe 'with channel: value' do
          let(:channel) { :notifications }

          it { expect(subject.unsubscribe_all(channel:)).to be == [] }
        end

        wrap_deferred 'when the subscriber has many subscriptions' do
          let!(:matching_subscriptions) { message_subscriptions.to_a }

          it { expect(subject.unsubscribe_all).to be == matching_subscriptions }

          it 'should remove the subscriptions' do
            expect { subject.unsubscribe_all }.to(
              change { message_subscriptions }.to(be == Set.new)
            )
          end

          it 'should delegate to #remove_subscription', :aggregate_failures do # rubocop:disable RSpec/ExampleLength
            subject.unsubscribe_all

            matching_subscriptions.each do |subscription|
              expect(subscription.publisher)
                .to have_received(:remove_subscription)
                .with(subscription)
            end
          end

          describe 'with channel: value' do
            let(:channel) { :notifications }
            let!(:matching_subscriptions) do
              message_subscriptions.select do |subscription|
                subscription.channel == channel
              end
            end

            it 'should return the matching subscriptions' do
              expect(subject.unsubscribe_all(channel:))
                .to be == matching_subscriptions
            end

            it 'should remove the subscriptions', :aggregate_failures do # rubocop:disable RSpec/ExampleLength
              expect { subject.unsubscribe_all(channel:) }.to(
                change { message_subscriptions.count }.by(-2) # rubocop:disable RSpec/ExpectChange
              )

              matching_subscriptions.each do |subscription|
                expect(message_subscriptions).not_to include subscription
              end
            end

            it 'should delegate to #remove_subscription', :aggregate_failures do # rubocop:disable RSpec/ExampleLength
              subject.unsubscribe_all

              matching_subscriptions.each do |subscription|
                expect(subscription.publisher)
                  .to have_received(:remove_subscription)
                  .with(subscription)
              end
            end
          end
        end
      end
    end
  end
end
