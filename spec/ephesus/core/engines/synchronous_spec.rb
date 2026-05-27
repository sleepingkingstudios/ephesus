# frozen_string_literal: true

require 'ephesus/core/engine'
require 'ephesus/core/engines/synchronous'
require 'ephesus/core/rspec/deferred/engines_examples'

RSpec.describe Ephesus::Core::Engines::Synchronous do
  include Ephesus::Core::RSpec::Deferred::EnginesExamples

  subject(:engine) { described_class.new }

  let(:described_class) { Spec::SynchronousEngine }

  example_class 'Spec::SynchronousEngine', Ephesus::Core::Engine do |klass|
    klass.include Ephesus::Core::Engines::Synchronous # rubocop:disable RSpec/DescribedClass
  end

  include_deferred 'should implement the event handling interface'

  include_deferred 'should implement the event handling methods'

  describe '#enqueue_event' do
    let(:event) { Ephesus::Core::Message.new }
    let(:scene) { Ephesus::Core::Scene.new }

    define_method :process_event do
      subject.send(:enqueue_event, event:, scene:)
    end

    define_method :queued_events do
      queue  = scene.send(:event_queue)
      events = []

      events << queue.pop until queue.empty?

      events
    end

    context 'when the scene does not handle the event' do
      let(:error_class) do
        Ephesus::Core::Scenes::EventHandling::UnhandledEventError
      end
      let(:error_message) do
        'no event handler found for event ephesus.core'
      end

      it 'should raise an exception' do
        expect { process_event }
          .to raise_error(error_class, error_message)
      end

      it 'should not enqueue the event' do
        process_event rescue error_class # rubocop:disable Style/RescueModifier

        expect(queued_events).to be == []
      end
    end

    context 'when the scene handles the event' do
      let(:event)            { Spec::CustomCommand::Event.new }
      let(:scene)            { Spec::CustomScene.new }
      let(:processed_events) { [] }

      example_class 'Spec::CustomCommand', Ephesus::Core::Command do |klass|
        events = processed_events

        klass.const_set(:Event, Ephesus::Core::Message.define)

        klass.define_method(:process) do |event:, **|
          events << event

          success
        end
      end

      example_class 'Spec::CustomScene', Ephesus::Core::Scene do |klass|
        klass.handle_event Spec::CustomCommand
      end

      it 'should process the event' do
        process_event

        expect(processed_events).to be == [event]
      end

      it 'should not enqueue the event' do
        process_event

        expect(queued_events).to be == []
      end
    end
  end
end
