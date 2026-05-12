# frozen_string_literal: true

require 'ephesus/core/rspec/deferred/scenes_examples'
require 'ephesus/core/scenes/processing'

RSpec.describe Ephesus::Core::Scenes::Processing do
  include Ephesus::Core::RSpec::Deferred::ScenesExamples

  subject(:scene) { described_class.new(**constructor_options) }

  deferred_context 'when the scene has initial state' do |**initial_state|
    let(:state)               { initial_state }
    let(:constructor_options) { { state: } }
  end

  let(:described_class)     { Spec::ExampleScene }
  let(:constructor_options) { {} }

  example_class 'Spec::ExampleScene' do |klass|
    klass.include Ephesus::Core::Scenes::EventHandling
    klass.include Ephesus::Core::Scenes::Processing # rubocop:disable RSpec/DescribedClass
    klass.include Ephesus::Core::Scenes::SideEffects

    klass.define_method :initialize do |state: {}|
      super()

      @state = Ephesus::Core::State.new(state)
    end

    klass.attr_reader :state
  end

  include_deferred 'should implement the event processing interface'

  include_deferred 'should implement the event processing methods'
end
