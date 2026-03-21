# frozen_string_literal: true

require 'ephesus/core/actors/external_actor'
require 'ephesus/core/connection'
require 'ephesus/core/rspec/deferred/messages_examples'

RSpec.describe Ephesus::Core::Actors::ExternalActor do
  include Ephesus::Core::RSpec::Deferred::MessagesExamples

  subject(:actor) { described_class.new(connection:) }

  let(:connection) do
    Ephesus::Core::Connection.new(format: 'spec.example_format')
  end

  example_class 'Spec::Publisher' do |klass|
    klass.include Ephesus::Core::Messaging::Publisher
  end

  example_class 'Spec::Subscriber' do |klass|
    klass.include Ephesus::Core::Messaging::Subscriber

    klass.define_method(:messages) { @messages ||= [] }

    klass.define_method(:receive_message) { |message| messages << message }
  end

  include_deferred 'should subscribe to messages'

  describe '.new' do
    it 'should define the constructor' do
      expect(described_class)
        .to be_constructible
        .with(0).arguments
        .and_keywords(:connection)
    end
  end

  describe '#as_json' do
    let(:expected) { { 'id' => actor.id, 'connection_id' => connection.id } }

    include_examples 'should define reader', :as_json, -> { expected }
  end

  describe '#connection' do
    include_examples 'should define reader', :connection, -> { connection }
  end

  describe '#handle_notification' do
    let(:message)    { Ephesus::Core::Message.new }
    let(:subscriber) { Spec::Subscriber.new }

    before(:example) do
      actor.add_subscription(subscriber, channel: :notifications)
    end

    it { expect(actor).to respond_to(:handle_notification).with(1).argument }

    it 'should publish the message to :notifications' do
      actor.handle_notification(message)

      expect(subscriber.messages).to be == [message]
    end
  end

  describe '#id' do
    let(:expected_format) { /\A\h{8}-\h{4}-\h{4}-\h{4}-\h{12}\z/ }

    include_examples 'should define reader',
      :id,
      -> { be_a(String).and match(expected_format) }
  end
end
