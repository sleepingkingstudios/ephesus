# frozen_string_literal: true

require 'ephesus/core/actor'
require 'ephesus/core/rspec/deferred/messages_examples'

RSpec.describe Ephesus::Core::Actor do
  include Ephesus::Core::RSpec::Deferred::MessagesExamples

  subject(:actor) { described_class.new(**constructor_options) }

  let(:constructor_options) { {} }

  example_class 'Spec::Publisher' do |klass|
    klass.include Ephesus::Core::Messaging::Publisher
  end

  example_class 'Spec::Subscriber' do |klass|
    klass.include Ephesus::Core::Messaging::Subscriber

    klass.define_method(:messages) { @messages ||= [] }

    klass.define_method(:receive_message) { |message| messages << message }
  end

  include_deferred 'should subscribe to messages'

  describe '.initialize' do
    it 'should define the constructor' do
      expect(described_class)
        .to be_constructible
        .with(0).arguments
        .and_keywords(:user)
    end
  end

  describe '#agent?' do
    include_examples 'should define predicate', :agent?, false

    context 'when initialized with user: false' do
      let(:constructor_options) { super().merge(user: false) }

      it { expect(actor.agent?).to be true }
    end

    context 'when initialized with user: true' do
      let(:constructor_options) { super().merge(user: true) }

      it { expect(actor.agent?).to be false }
    end
  end

  describe '#as_json' do
    let(:expected) { { 'id' => actor.id } }

    include_examples 'should define reader', :as_json, -> { expected }
  end

  describe '#current_scene' do
    include_examples 'should define reader', :current_scene, nil

    context 'when the actor has a current scene' do
      let(:scene) { Ephesus::Core::Scene.new }

      before(:example) { actor.current_scene = scene }

      it { expect(actor.current_scene).to be scene }
    end
  end

  describe '#current_scene=' do
    let(:scene) { Ephesus::Core::Scene.new }

    include_examples 'should define writer', :current_scene=

    it 'should set the current scene' do
      expect { actor.current_scene = scene }
        .to change(actor, :current_scene)
        .to be scene
    end
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

  describe '#handle_connection_update' do
    let(:message)    { Ephesus::Core::Message.new }
    let(:subscriber) { Spec::Subscriber.new }

    before(:example) do
      actor.add_subscription(subscriber, channel: :connection_updates)
    end

    it 'should define the method' do
      expect(actor).to respond_to(:handle_connection_update).with(1).argument
    end

    it 'should publish the message to :connection_updates' do
      actor.handle_connection_update(message)

      expect(subscriber.messages).to be == [message]
    end
  end

  describe '#id' do
    let(:expected_format) { /\A\h{8}-\h{4}-\h{4}-\h{4}-\h{12}\z/ }

    include_examples 'should define reader',
      :id,
      -> { be_a(String).and match(expected_format) }
  end

  describe '#inspect' do
    let(:expected) do
      "#<#{described_class.name} id=#{actor.id.inspect} user=#{actor.user?} " \
        "current_scene=#{actor.current_scene.inspect}>"
    end

    it { expect(actor.inspect).to be == expected }

    context 'when the actor has a current scene' do
      let(:scene) { Ephesus::Core::Scene.new }

      before(:example) { actor.current_scene = scene }

      it { expect(actor.inspect).to be == expected }
    end
  end

  describe '#user?' do
    include_examples 'should define predicate', :user?, true

    context 'when initialized with user: false' do
      let(:constructor_options) { super().merge(user: false) }

      it { expect(actor.user?).to be false }
    end

    context 'when initialized with user: true' do
      let(:constructor_options) { super().merge(user: true) }

      it { expect(actor.user?).to be true }
    end
  end
end
