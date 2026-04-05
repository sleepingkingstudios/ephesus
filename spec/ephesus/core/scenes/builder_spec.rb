# frozen_string_literal: true

require 'ephesus/core/scene'
require 'ephesus/core/scenes/builder'

RSpec.describe Ephesus::Core::Scenes::Builder do
  subject(:builder) { described_class.new(scene_class, **static_options) }

  let(:scene_class)    { Class.new(Ephesus::Core::Scene) }
  let(:static_options) { {} }

  describe '.new' do
    it 'should define the constructor' do
      expect(described_class)
        .to be_constructible
        .with(1).argument
        .and_any_keywords
    end
  end

  describe '#call' do
    let(:options)        { {} }
    let(:scene)          { builder.call(**options).value }
    let(:expected_value) { an_instance_of(scene_class) }
    let(:expected_state) { { 'actors' => {} } }

    it 'should define the method' do
      expect(builder)
        .to be_callable
        .with(0).arguments
        .and_any_keywords
    end

    it { expect(builder).to have_aliased_method(:call).as(:build) }

    it 'should return a passing result' do
      expect(builder.call(**options))
        .to be_a_passing_result
        .with_value(expected_value)
    end

    it { expect(scene.state.to_h).to be == expected_state }

    context 'with a builder subclass' do
      let(:described_class) { Spec::CustomBuilder }
      let(:scene_class)     { Spec::CustomScene }
      let(:expected_state)  { super().merge('difficulty' => :normal) }

      # rubocop:disable RSpec/DescribedClass
      example_class 'Spec::CustomBuilder', Ephesus::Core::Scenes::Builder \
      do |klass|
        klass.define_method :build_state do |difficulty: :normal, **options|
          unless %i[easy normal hard insane].include?(difficulty)
            message = "invalid difficulty #{difficulty.inspect}"
            error   = Cuprum::Error.new(message:)

            return failure(error)
          end

          super().merge(difficulty:, **options.except(:ironman))
        end

        klass.define_method :build_scene do |state, ironman: false, **|
          return super(state) unless ironman

          Spec::IronmanScene.new(state:)
        end
      end
      # rubocop:enable RSpec/DescribedClass

      example_class 'Spec::CustomScene', Ephesus::Core::Scene

      example_class 'Spec::IronmanScene', 'Spec::CustomScene'

      it 'should return a passing result' do
        expect(builder.call(**options))
          .to be_a_passing_result
          .with_value(expected_value)
      end

      it { expect(scene.state.to_h).to be == expected_state }

      describe 'with options: invalid value' do
        let(:options) { super().merge(difficulty: :ludicrous) }
        let(:expected_error) do
          Cuprum::Error.new(message: 'invalid difficulty :ludicrous')
        end

        it 'should return a failing result' do
          expect(builder.call(**options))
            .to be_a_failing_result
            .with_error(expected_error)
        end
      end

      describe 'with options: valid value' do
        let(:options) do
          super().merge(difficulty: :insane, ironman: true)
        end
        let(:expected_value) { an_instance_of(Spec::IronmanScene) }
        let(:expected_state) { super().merge('difficulty' => :insane) }

        it 'should return a passing result' do
          expect(builder.call(**options))
            .to be_a_passing_result
            .with_value(expected_value)
        end

        it { expect(scene.state.to_h).to be == expected_state }
      end

      context 'when initialized with static options' do
        let(:static_options) do
          super().merge(difficulty: :hard, enable_debug: true)
        end
        let(:expected_state) do
          super().merge('difficulty' => :hard, 'enable_debug' => true)
        end

        it { expect(scene.state.to_h).to be == expected_state }

        describe 'with options: valid value' do
          let(:options) do
            super().merge(difficulty: :insane, ironman: true)
          end
          let(:expected_value) { an_instance_of(Spec::IronmanScene) }
          let(:expected_state) { super().merge('difficulty' => :insane) }

          it 'should return a passing result' do
            expect(builder.call(**options))
              .to be_a_passing_result
              .with_value(expected_value)
          end

          it { expect(scene.state.to_h).to be == expected_state }
        end
      end
    end
  end

  describe '#scene_class' do
    include_examples 'should define reader', :scene_class, -> { scene_class }
  end

  describe '#static_options' do
    include_examples 'should define reader', :static_options, -> { {} }

    context 'when initialized with static options' do
      let(:static_options) do
        super().merge(difficulty: :hard, enable_debug: true)
      end

      it { expect(builder.static_options).to be == static_options }
    end
  end

  describe '#type' do
    include_examples 'should define reader', :type, -> { scene_class.type }
  end
end
