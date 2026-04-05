# frozen_string_literal: true

require 'ephesus/core/engines/connection_management'
require 'ephesus/core/rspec/deferred/engines_examples'
require 'ephesus/core/rspec/deferred/messages_examples'

RSpec.describe Ephesus::Core::Engines::ConnectionManagement do
  include Ephesus::Core::RSpec::Deferred::EnginesExamples
  include Ephesus::Core::RSpec::Deferred::MessagesExamples

  subject(:engine) { described_class.new }

  let(:described_class) { Spec::CustomEngine }

  example_class 'Spec::CustomEngine' do |klass|
    klass.include Ephesus::Core::Engines::ConnectionManagement # rubocop:disable RSpec/DescribedClass
  end

  example_class 'Spec::Publisher' do |klass|
    klass.include Ephesus::Core::Messaging::Publisher
  end

  describe '::ConnectionError' do
    include_examples 'should define constant',
      :ConnectionError,
      -> { be_a(Class).and(be < StandardError) }
  end

  include_deferred 'should subscribe to messages'

  include_deferred 'should implement the connection management interface'

  include_deferred 'should implement the connection management methods'

  describe '#add_connection' do
    let(:connection) do
      Ephesus::Core::Connection.new(format: 'spec.format')
    end

    before(:example) do
      allow(engine).to receive(:enqueue_event) # rubocop:disable RSpec/SubjectStub
    end

    context 'when the engine defines a default scene' do
      let(:default_scene) { Ephesus::Core::Scene.new }
      let(:connect_event) do
        Ephesus::Core::Commands::ConnectActor::Event.new(connection.actor)
      end

      before(:example) do
        scene = default_scene

        described_class.define_method(:default_scene) { scene }
      end

      it 'should set the current scene for the actor' do
        engine.add_connection(connection)

        expect(connection.actor.current_scene).to be default_scene
      end

      it 'should enqueue a ConnectActor event' do
        engine.add_connection(connection)

        expect(engine) # rubocop:disable RSpec/SubjectStub
          .to have_received(:enqueue_event)
          .with(event: connect_event, scene: default_scene)
      end
    end
  end

  describe '#build_actor' do
    let(:connection) { Ephesus::Core::Connection.new(format: 'spec.format') }
    let(:actor)      { subject.send(:build_actor, connection) }

    it { expect(actor).to be_a Ephesus::Core::Actors::ExternalActor }

    it { expect(actor.connection).to be connection }
  end
end
