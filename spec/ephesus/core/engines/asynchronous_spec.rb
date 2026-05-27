# frozen_string_literal: true

require 'ephesus/core/engine'
require 'ephesus/core/engines/asynchronous'
require 'ephesus/core/rspec/deferred/engines_examples'

RSpec.describe Ephesus::Core::Engines::Asynchronous do
  include Ephesus::Core::RSpec::Deferred::EnginesExamples

  subject(:engine) { described_class.new(**constructor_options) }

  let(:described_class)     { Spec::CustomEngine }
  let(:constructor_options) { {} }

  example_class 'Spec::CustomEngine', Ephesus::Core::Engine do |klass|
    klass.include Ephesus::Core::Engines::Asynchronous # rubocop:disable RSpec/DescribedClass
  end

  around(:example) do |example|
    if example.metadata[:async]
      Sync { example.call }
    else
      example.call
    end
  ensure
    engine.stop
  end

  include_deferred 'should implement the event handling interface'

  include_deferred 'should implement the event handling methods'

  describe '.new' do
    it 'should define the constructor' do
      expect(described_class)
        .to be_constructible
        .with(0).arguments
        .and_keywords(:worker_limit)
        .and_any_keywords
    end
  end

  describe '#enqueue_event' do
    let(:event) { Ephesus::Core::Message.new }
    let(:scene) do
      engine
        .get_scene('spec.scenes.battle')
        .tap do |scene|
          allow(scene).to receive(:call)
          allow(scene).to receive(:enqueue_event).and_call_original
        end
    end
    let(:workers) { engine.send(:workers) }

    include_deferred 'when the engine manages scenes'

    it 'should delegate to the scene' do
      engine.send(:enqueue_event, event:, scene:)

      expect(scene).to have_received(:enqueue_event).with(event)
    end

    it 'should not enqueue any async tasks' do
      allow(workers).to receive(:async)

      engine.send(:enqueue_event, event:, scene:)

      expect(workers).not_to have_received(:async)
    end

    context 'when the engine is running' do
      before(:example) { engine.start }

      it 'should create an async task to run the scene', :async do
        engine.send(:enqueue_event, event:, scene:)

        expect(scene).to have_received(:call)
      end
    end
  end

  describe '#running?' do
    include_examples 'should define predicate', :running?, false

    context 'when the engine is running' do
      before(:example) { engine.start }

      it { expect(engine.running?).to be true }
    end
  end

  describe '#start' do
    deferred_context 'when the engine has scenes with queued events' do
      let(:event)         { Ephesus::Core::Message.new }
      let(:called_scenes) { [] }
      let(:scenes) do
        [
          engine.get_scene('spec.scenes.battle'),
          engine.get_scene('spec.fantasy.conversation'),
          engine.get_scene('spec.fantasy.inventory')
        ].each do |scene|
          allow(scene).to receive(:call) do
            called_scenes << scene

            false
          end
        end
      end

      define_method :enqueue_events do
        subject.send(:enqueue_event, event:, scene: scenes[0])
        subject.send(:enqueue_event, event:, scene: scenes[0])

        subject.send(:enqueue_event, event:, scene: scenes[2])

        called_scenes.clear
      end
    end

    let(:workers) { engine.send(:workers) }

    include_deferred 'when the engine manages scenes'

    it { expect(engine).to respond_to(:start).with(0).arguments }

    it 'should start the engine' do
      expect { engine.start }
        .to change(engine, :running?)
        .to be true
    end

    it 'should not enqueue any async tasks' do
      allow(workers).to receive(:async)

      engine.start

      expect(workers).not_to have_received(:async)
    end

    wrap_deferred 'when the engine has scenes with queued events' do
      it 'should create async tasks for each waiting scene', :async do
        enqueue_events

        engine.start

        expect(called_scenes).to be == [scenes[0], scenes[2]]
      end
    end

    context 'when the engine is running' do
      before(:example) { engine.start }

      it 'should not start the engine' do
        expect { engine.start }.not_to change(engine, :running?)
      end

      it 'should not enqueue any async tasks' do
        allow(workers).to receive(:async)

        engine.start

        expect(workers).not_to have_received(:async)
      end

      wrap_deferred 'when the engine has scenes with queued events' do
        it 'should not enqueue any async tasks', :async do
          enqueue_events

          engine.start

          expect(called_scenes).to be == []
        end
      end
    end
  end

  describe '#stop' do
    it { expect(engine).to respond_to(:stop).with(0).arguments }

    context 'when the engine is running' do
      let(:workers) { engine.send(:workers) }

      before(:example) { engine.start }

      it 'should stop the engine' do
        expect { engine.stop }
          .to change(engine, :running?)
          .to be false
      end

      it 'should wait for tasks to finish', :async do # rubocop:disable RSpec/ExampleLength
        finished = false

        workers.async do
          sleep 0.1

          finished = true
        end

        engine.stop

        expect(finished).to be true
      end
    end
  end

  describe '#worker_limit' do
    include_examples 'should define private reader', :worker_limit, 5

    context 'when initialized with worker_limit: value' do
      let(:constructor_options) { super().merge(worker_limit: 10) }

      it { expect(engine.send(:worker_limit)).to be 10 }
    end
  end

  describe '#workers' do
    include_examples 'should define private reader',
      :workers,
      -> { be_a(Async::Semaphore) }

    it 'should limit the number of async workers' do
      expect(engine.send(:workers).limit).to be == engine.send(:worker_limit)
    end

    context 'when initialized with worker_limit: value' do
      let(:constructor_options) { super().merge(worker_limit: 10) }

      it 'should limit the number of async workers' do
        expect(engine.send(:workers).limit).to be == engine.send(:worker_limit)
      end
    end
  end
end
