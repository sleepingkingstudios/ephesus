# frozen_string_literal: true

require 'ephesus/core/messages/subscriber'

RSpec.describe Ephesus::Core::Messages::Subscriber do
  subject(:subscriber) { described_class.new }

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
      subscriber.subscribe(default_publisher)
      subscriber.subscribe(
        events_publisher,
        channel: :events
      )
      subscriber.subscribe(
        notifications_publisher,
        channel: :notifications
      )
      subscriber.subscribe(omni_publisher)
      subscriber.subscribe(
        omni_publisher,
        channel: :events
      )
      subscriber.subscribe(
        omni_publisher,
        channel: :notifications
      )
    end
  end

  let(:described_class) { Spec::Subscriber }

  example_constant 'Spec::Notification' do
    Ephesus::Core::Message.define(:message)
  end

  example_class 'Spec::Publisher' do |klass|
    klass.include Ephesus::Core::Messages::Publisher
  end

  example_class 'Spec::Subscriber' do |klass|
    klass.include Ephesus::Core::Messages::Subscriber # rubocop:disable RSpec/DescribedClass
  end

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
        subscriber:,
        **options
      )
    end

    define_method(:add_subscription) do
      subscriber.subscribe(publisher, **options, &block)
    end

    define_method(:message_subscriptions) do
      subscriber.send(:message_subscriptions)
    end

    it 'should define the method' do
      expect(subscriber)
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
      subscriber.send(:message_subscriptions)
    end

    it 'should define the method' do
      expect(subscriber)
        .to respond_to(:unsubscribe)
        .with(1).argument
        .and_keywords(:channel)
    end

    describe 'with a publisher' do
      let(:options) { {} }

      define_method(:remove_subscription) do
        subscriber.unsubscribe(publisher, **options)
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
          subscriber:
        )
      end

      define_method(:remove_subscription) do
        subscriber.unsubscribe(subscription)
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
          subscriber.unsubscribe(publisher, **options)
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

          describe 'with channel: value' do # rubocop:disable RSpec/NestedGroups
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

          it 'should delegate to #remove_subscription', :aggregate_failures do # rubocop:disable RSpec/ExampleLength
            remove_subscription

            matching_subscriptions.each do |subscription|
              expect(publisher)
                .to have_received(:remove_subscription)
                .with(subscription)
            end
          end

          describe 'with channel: value' do # rubocop:disable RSpec/NestedGroups
            let(:channel) { :notifications }
            let(:options) { super().merge(channel:) }
            let!(:matching_subscriptions) do
              super().select do |subscription|
                subscription.channel == channel
              end
            end
            let!(:matching_subscription) { matching_subscriptions.first }

            it { expect(remove_subscription).to be == matching_subscription }

            it 'should remove the subscription', :aggregate_failures do
              expect { remove_subscription }.to(
                change { message_subscriptions.count }.by(-1) # rubocop:disable RSpec/ExpectChange
              )

              expect(message_subscriptions).not_to include matching_subscription
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
          subscriber.unsubscribe(subscription)
        end

        context 'when the subscriber does not include the subscription' do
          let(:subscription) do
            Ephesus::Core::Messages::Subscription.new(
              channel:    :default,
              publisher:,
              subscriber:
            )
          end

          it { expect(remove_subscription).to be nil }

          it 'should delegate to #remove_subscription' do
            remove_subscription

            expect(publisher)
              .to have_received(:remove_subscription)
              .with(subscription)
          end

          context 'when the publisher included the subscription' do # rubocop:disable RSpec/NestedGroups
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

          context 'when the publisher included the subscription' do # rubocop:disable RSpec/NestedGroups
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
      subscriber.send(:message_subscriptions)
    end

    it 'should define the method' do
      expect(subscriber)
        .to respond_to(:unsubscribe_all)
        .with(0).arguments
        .and_keywords(:channel)
    end

    it { expect(subscriber.unsubscribe_all).to be == [] }

    describe 'with channel: value' do
      let(:channel) { :notifications }

      it { expect(subscriber.unsubscribe_all(channel:)).to be == [] }
    end

    wrap_deferred 'when the subscriber has many subscriptions' do
      let!(:matching_subscriptions) { message_subscriptions.to_a }

      it { expect(subscriber.unsubscribe_all).to be == matching_subscriptions }

      it 'should remove the subscriptions' do
        expect { subscriber.unsubscribe_all }.to(
          change { message_subscriptions }.to(be == Set.new)
        )
      end

      it 'should delegate to #remove_subscription', :aggregate_failures do # rubocop:disable RSpec/ExampleLength
        subscriber.unsubscribe_all

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
          expect(subscriber.unsubscribe_all(channel:))
            .to be == matching_subscriptions
        end

        it 'should remove the subscriptions', :aggregate_failures do # rubocop:disable RSpec/ExampleLength
          expect { subscriber.unsubscribe_all(channel:) }.to(
            change { message_subscriptions.count }.by(-2) # rubocop:disable RSpec/ExpectChange
          )

          matching_subscriptions.each do |subscription|
            expect(message_subscriptions).not_to include subscription
          end
        end

        it 'should delegate to #remove_subscription', :aggregate_failures do # rubocop:disable RSpec/ExampleLength
          subscriber.unsubscribe_all

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
