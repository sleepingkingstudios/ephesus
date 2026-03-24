# frozen_string_literal: true

require 'ephesus/core/connection'
require 'ephesus/core/rspec/deferred/messages_examples'

RSpec.describe Ephesus::Core::Connection do
  include Ephesus::Core::RSpec::Deferred::MessagesExamples

  subject(:connection) { described_class.new(**constructor_options) }

  let(:format)              { 'spec.example_format' }
  let(:constructor_options) { { format: } }

  example_class 'Spec::Subscriber' do |klass|
    klass.define_method(:messages) { @messages ||= [] }

    klass.define_method(:receive_message) { |message| messages << message }
  end

  define_method :build_publisher do
    return super() if defined?(super())

    described_class.new(format:)
  end

  include_deferred 'should publish messages'

  describe '::FormatNotFoundError' do
    include_examples 'should define constant',
      :FormatNotFoundError,
      -> { be_a(Class).and(be < StandardError) }
  end

  describe '.new' do
    it 'should define the constructor' do
      expect(described_class)
        .to be_constructible
        .with(0).arguments
        .and_keywords(:format)
    end
  end

  describe '#actor' do
    include_examples 'should define reader', :actor, nil
  end

  describe '#actor=' do
    let(:actor) { Object.new.freeze }

    include_examples 'should define writer', :actor=

    it 'should set the actor' do
      expect { connection.actor = actor }
        .to change(connection, :actor)
        .to be actor
    end
  end

  describe '#format' do
    include_examples 'should define reader', :format
  end

  describe '#format_options' do
    include_examples 'should define private reader', :format_options, {}
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

  describe '#formatter' do
    let(:error_message) do
      "Formatter not found with format #{connection.format.inspect}"
    end

    it { expect(connection).to respond_to(:formatter).with(0).arguments }

    context 'when there is not a matching formatter' do
      it 'should raise an exception' do
        expect { connection.formatter }
          .to raise_error described_class::FormatNotFoundError, error_message
      end
    end

    context 'when initialized with formats: value' do
      let(:formats) do
        { 'spec.custom' => Spec::CustomFormatter }
      end
      let(:constructor_options) { super().merge(formats:) }

      example_class 'Spec::CustomFormatter' do |klass|
        klass.define_method :initialize do |**options|
          @options = options
        end

        klass.attr_reader :options
      end

      context 'when there is not a matching formatter' do
        it 'should raise an exception' do
          expect { connection.formatter }
            .to raise_error described_class::FormatNotFoundError, error_message
        end
      end

      context 'when there is a matching formatter' do
        let(:format) { 'spec.custom' }

        it { expect(connection.formatter).to be_a Spec::CustomFormatter }

        it { expect(connection.formatter.options).to be == {} }

        context 'when the connection defines format options' do
          let(:format_options) { { locale: 'swedish-chef' } }

          before(:example) do
            allow(connection) # rubocop:disable RSpec/SubjectStub
              .to receive(:format_options)
              .and_return(format_options)
          end

          it { expect(connection.formatter.options).to be == format_options }
        end
      end
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
    let(:message) { Ephesus::Core::Message.new }

    it 'should define the method' do
      expect(connection).to respond_to(:handle_notification).with(1).argument
    end

    it { expect(connection.handle_notification(message)).to be nil }
  end

  describe '#id' do
    let(:expected_format) { /\A\h{8}-\h{4}-\h{4}-\h{4}-\h{12}\z/ }

    include_examples 'should define reader',
      :id,
      -> { be_a(String).and match(expected_format) }
  end
end
