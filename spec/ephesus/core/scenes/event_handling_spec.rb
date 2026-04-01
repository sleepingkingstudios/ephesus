# frozen_string_literal: true

require 'ephesus/core/rspec/deferred/scenes_examples'
require 'ephesus/core/scenes/event_handling'

RSpec.describe Ephesus::Core::Scenes::EventHandling do
  include Ephesus::Core::RSpec::Deferred::ScenesExamples

  subject(:scene) { described_class.new }

  let(:described_class) { Spec::CustomScene }

  example_class 'Spec::CustomScene' do |klass|
    klass.include Ephesus::Core::Scenes::EventHandling # rubocop:disable RSpec/DescribedClass

    klass.define_method(:initialize) { @state = Ephesus::Core::State.new({}) }

    klass.attr_reader :state
  end

  include_deferred 'should implement the event handling interface'

  include_deferred 'should implement the event handling methods'

  describe '.handle_event' do
    let(:command_class) { Spec::CustomCommand }
    let(:options)       { {} }

    example_class 'Spec::CustomCommand', Ephesus::Core::Command

    context 'when the class is abstract' do
      let(:error_message) do
        "unable to add event handler for abstract class #{described_class.name}"
      end

      before(:example) do
        Spec::CustomScene.define_singleton_method(:abstract?) { true }
      end

      it 'should raise an exception' do
        expect { described_class.handle_event(command_class) }
          .to raise_error described_class::AbstractClassError, error_message
      end

      describe 'with force: true' do
        it 'should register the event handler' do
          described_class.handle_event(command_class, force: true)

          expect(described_class.handled_events[command_class.type])
            .to be command_class
        end
      end
    end
  end
end
