# frozen_string_literal: true

require 'ephesus/core/connection'
require 'ephesus/core/rspec/deferred/messages_examples'

RSpec.describe Ephesus::Core::Connection do
  include Ephesus::Core::RSpec::Deferred::MessagesExamples

  subject(:connection) { described_class.new(**constructor_options) }

  let(:format)              { 'spec.example_format' }
  let(:constructor_options) { { format: } }

  example_class 'Spec::Publisher' do |klass|
    klass.include Ephesus::Core::Messaging::Publisher
  end

  example_class 'Spec::Subscriber' do |klass|
    klass.define_method(:messages) { @messages ||= [] }

    klass.define_method(:receive_message) { |message| messages << message }
  end

  define_method :build_publisher do
    described_class.new(format:)
  end

  include_deferred 'should publish messages'

  include_deferred 'should subscribe to messages'

  describe '::FormatErrorNotificationError' do
    include_examples 'should define constant',
      :FormatErrorNotificationError,
      -> { be_a(Class).and(be < StandardError) }
  end

  describe '.new' do
    it 'should define the constructor' do
      expect(described_class)
        .to be_constructible
        .with(0).arguments
        .and_keywords(:data, :format)
    end
  end

  describe '#actor' do
    include_examples 'should define reader', :actor, nil
  end

  describe '#actor=' do
    let(:message) { Ephesus::Core::Message.new }

    before(:example) do
      allow(connection).to receive(:handle_notification) # rubocop:disable RSpec/SubjectStub
    end

    include_examples 'should define writer', :actor=

    describe 'with nil' do
      let(:error_message) do
        SleepingKingStudios::Tools::Toolbelt
          .instance
          .assertions
          .error_message_for(
            :instance_of,
            as:       'actor',
            expected: Ephesus::Core::Actor
          )
      end

      it 'should raise an exception' do
        expect { connection.actor = nil }
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with an Object' do
      let(:error_message) do
        SleepingKingStudios::Tools::Toolbelt
          .instance
          .assertions
          .error_message_for(
            :instance_of,
            as:       'actor',
            expected: Ephesus::Core::Actor
          )
      end

      it 'should raise an exception' do
        expect { connection.actor = Object.new.freeze }
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with an Actor' do
      let(:actor) { Ephesus::Core::Actor.new }

      it { expect(connection.actor = actor).to be actor }

      it 'should set the actor' do
        expect { connection.actor = actor }
          .to change(connection, :actor)
          .to be actor
      end

      it 'should subscribe the connection to actor notifications' do
        connection.actor = actor

        actor.publish(message, channel: :notifications)

        expect(connection).to have_received(:handle_notification).with(message) # rubocop:disable RSpec/SubjectStub
      end

      context 'when the connection already references an actor' do
        let(:original_actor) { Ephesus::Core::Actor.new }

        before(:example) { connection.actor = original_actor }

        it 'should set the actor' do
          expect { connection.actor = actor }
            .to change(connection, :actor)
            .to be actor
        end

        it 'should subscribe the connection to actor notifications' do
          connection.actor = actor

          actor.publish(message, channel: :notifications)

          expect(connection) # rubocop:disable RSpec/SubjectStub
            .to have_received(:handle_notification)
            .with(message)
        end

        it 'should unsubscribe from the previous actor' do
          connection.actor = actor

          original_actor.publish(message, channel: :notifications)

          expect(connection).not_to have_received(:handle_notification) # rubocop:disable RSpec/SubjectStub
        end
      end
    end
  end

  describe '#data' do
    include_examples 'should define reader', :data, -> { {} }

    context 'when initialized with data: value' do
      let(:data)                { { name: 'Alan Bradley' } }
      let(:constructor_options) { super().merge(data:) }

      it { expect(connection.data).to be == data }
    end
  end

  describe '#format' do
    include_examples 'should define reader', :format
  end

  describe '#format_input' do
    let(:event) { Ephesus::Core::Message.new }
    let(:scene) { Ephesus::Core::Scene.new }

    it 'should define the method' do
      expect(connection)
        .to respond_to(:format_input)
        .with(0).arguments
        .and_keywords(:event, :scene)
        .and_any_keywords
    end

    context 'when there is not a matching formatter' do
      let(:expected_error) do
        Ephesus::Core::Formats::Errors::FormatNotFound.new(
          format:,
          message: 'unable to format input'
        )
      end

      it 'should return a failing result' do
        expect(connection.format_input(event:, scene:))
          .to be_a_failing_result
          .with_error(expected_error)
      end
    end

    context 'when there is a matching formatter' do
      let(:format)    { 'spec.custom' }
      let(:formats)   { { 'spec.custom' => Spec::CustomFormatter } }
      let(:formatter) { subject.send(:formatter) }
      let(:result)    { Cuprum::Result.new(value: expected_value) }
      let(:expected_value) do
        { 'ok' => true, value: 'formatted input' }
      end
      let(:constructor_options) do
        super().merge(formats:)
      end

      example_class 'Spec::CustomFormatter' do |klass|
        format_result = result

        klass.define_method :initialize do |**options|
          @options = options
        end

        klass.attr_reader :options

        klass.define_method :format_input do |**|
          format_result
        end
      end

      it 'should return a passing result' do
        expect(connection.format_input(event:, scene:))
          .to be_a_passing_result
          .with_value(expected_value)
      end
    end
  end

  describe '#format_options' do
    include_examples 'should define private reader', :format_options, {}
  end

  describe '#format_output' do
    let(:notification) { Ephesus::Core::Message.new }

    it 'should define the method' do
      expect(connection)
        .to respond_to(:format_output)
        .with(0).arguments
        .and_keywords(:notification)
        .and_any_keywords
    end

    context 'when there is not a matching formatter' do
      let(:expected_error) do
        Ephesus::Core::Formats::Errors::FormatNotFound.new(
          format:,
          message: 'unable to format output'
        )
      end

      it 'should return a failing result' do
        expect(connection.format_output(notification:))
          .to be_a_failing_result
          .with_error(expected_error)
      end
    end

    context 'when there is a matching formatter' do
      let(:format)    { 'spec.custom' }
      let(:formats)   { { 'spec.custom' => Spec::CustomFormatter } }
      let(:formatter) { subject.send(:formatter) }
      let(:result)    { Cuprum::Result.new(value: expected_value) }
      let(:expected_value) do
        { 'ok' => true, value: 'formatted output' }
      end
      let(:constructor_options) do
        super().merge(formats:)
      end

      example_class 'Spec::CustomFormatter' do |klass|
        format_result = result

        klass.define_method :initialize do |**options|
          @options = options
        end

        klass.attr_reader :options

        klass.define_method :format_output do |**|
          format_result
        end
      end

      it 'should return a passing result' do
        expect(connection.format_output(notification:))
          .to be_a_passing_result
          .with_value(expected_value)
      end
    end
  end

  describe '#formats' do
    include_examples 'should define private reader', :formats

    context 'when initialized with formats: value' do
      let(:formats) do
        { 'spec.custom' => Spec::CustomFormatter }
      end
      let(:constructor_options) { super().merge(formats:) }

      example_class 'Spec::CustomFormatter'

      it { expect(connection.send(:formats)).to be == formats }
    end
  end

  describe '#handle_input' do
    let(:subscriber) { Spec::Subscriber.new }
    let(:message)    { Spec::InputMessage.new(text: 'Greetings, programs!') }
    let(:expected_message) do
      Spec::InputMessage.new(connection:, text: 'Greetings, programs!')
    end

    example_constant 'Spec::InputMessage' do
      Ephesus::Core::Messages::LazyConnectionMessage.define(:text)
    end

    before(:example) do
      connection.add_subscription(subscriber, channel: :events)
    end

    it { expect(connection).to respond_to(:handle_input).with(1).argument }

    it 'should publish the message to :events' do
      connection.handle_input(message)

      expect(subscriber.messages).to be == [expected_message]
    end
  end

  describe '#handle_notification' do
    let(:actor) { Ephesus::Core::Actor.new }
    let(:notification) do
      Ephesus::Core::Messages::Notification.new(original_actor: actor)
    end

    it 'should define the method' do
      expect(connection).to respond_to(:handle_notification).with(1).argument
    end

    context 'when there is not a matching formatter' do
      let(:subscriber) { Spec::Subscriber.new }
      let(:error_message) do
        'unable to format output - format not found with type ' \
          '"spec.example_format"'
      end

      before(:example) do
        connection.add_subscription(subscriber, channel: :output)
      end

      it 'should raise an exception' do
        expect { connection.handle_notification(notification) }
          .to raise_error(
            described_class::FormatErrorNotificationError,
            error_message
          )
      end

      it 'should not publish a message' do
        connection.handle_notification(notification)
      rescue described_class::FormatErrorNotificationError
        expect(subscriber.messages).to be == []
      end
    end

    context 'when there is a matching formatter' do
      let(:format) { 'spec.custom' }
      let(:formats) do
        { 'spec.custom' => Spec::CustomFormatter }
      end
      let(:constructor_options) { super().merge(formats:) }
      let(:result) { Cuprum::Result.new }
      let(:formatter) do
        instance_double(
          Spec::CustomFormatter,
          format:,
          format_output: result
        )
      end
      let(:subscriber) { Spec::Subscriber.new }

      example_class 'Spec::CustomFormatter' do |klass|
        klass.define_method(:format_output) { |*| nil }
      end

      before(:example) do
        allow(Spec::CustomFormatter).to receive(:new).and_return(formatter)

        connection.add_subscription(subscriber, channel: :output)
      end

      context 'when the formatter returns a failing result' do
        let(:error)  { Cuprum::Error.new(message: 'Something went wrong') }
        let(:result) { Cuprum::Result.new(error:) }

        it 'should raise an exception' do
          expect { connection.handle_notification(notification) }
            .to raise_error(
              described_class::FormatErrorNotificationError,
              error.message
            )
        end

        it 'should not publish a message' do
          connection.handle_notification(notification)
        rescue described_class::FormatErrorNotificationError
          expect(subscriber.messages).to be == []
        end

        context 'when the formatter can format an ErrorNotification' do
          let(:expected_attributes) do
            {
              format:,
              error_id: an_instance_of(String),
              message:  error.message,
              details:  { 'type' => error.type }
            }
          end

          before(:example) do
            allow(formatter).to receive(:format_output) do |notification:, **|
              if notification.is_a?(Ephesus::Core::Messages::ErrorNotification)
                next Ephesus::Core::Formats::Commands::FormatOutput
                  .new(format:)
                  .call(notification)
              end

              result
            end
          end

          it 'should publish the error message', :aggregate_failures do
            connection.handle_notification(notification)

            expect(subscriber.messages.size).to be 1
            expect(subscriber.messages.first)
              .to be_a(Ephesus::Core::Formats::ErrorMessage)
              .and have_attributes(**expected_attributes)
          end
        end
      end

      context 'when the formatter returns a passing result' do
        let(:message) { Spec::OutputMessage.new(ok: true) }
        let(:result)  { Cuprum::Result.new(value: message) }

        example_constant 'Spec::OutputMessage' do
          Ephesus::Core::Message.define(:ok)
        end

        it 'should publish the formatted message' do
          connection.handle_notification(notification)

          expect(subscriber.messages).to be == [message]
        end
      end
    end
  end

  describe '#id' do
    let(:expected_format) { /\A\h{8}-\h{4}-\h{4}-\h{4}-\h{12}\z/ }

    include_examples 'should define reader',
      :id,
      -> { be_a(String).and match(expected_format) }
  end
end
