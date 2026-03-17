# frozen_string_literal: true

require 'ephesus/core/connection'
require 'ephesus/core/rspec/deferred/messages_examples'

RSpec.describe Ephesus::Core::Connection do
  include Ephesus::Core::RSpec::Deferred::MessagesExamples

  subject(:connection) { described_class.new(format:) }

  let(:format) { 'spec.example_format' }

  example_class 'Spec::Subscriber' do |klass|
    klass.define_method(:messages) { @messages ||= [] }

    klass.define_method(:receive_message) { |message| messages << message }
  end

  define_method :build_publisher do
    return super() if defined?(super())

    described_class.new(format:)
  end

  include_deferred 'should publish messages'

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

  describe '#id' do
    let(:expected_format) { /\A\h{8}-\h{4}-\h{4}-\h{4}-\h{12}\z/ }

    include_examples 'should define reader',
      :id,
      -> { be_a(String).and match(expected_format) }
  end
end
