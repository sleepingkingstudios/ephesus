# frozen_string_literal: true

require 'ephesus/core/rspec/deferred/messages_examples'
require 'ephesus/core/scene'
require 'ephesus/core/scenes/builder'
require 'ephesus/core/scenes/pool'

RSpec.describe Ephesus::Core::Scenes::Pool do
  include Ephesus::Core::RSpec::Deferred::MessagesExamples

  subject(:pool) { described_class.new(builder, **options) }

  let(:builder) do
    instance_double(
      Ephesus::Core::Scenes::Builder,
      call: nil,
      type: 'spec.custom'
    )
  end
  let(:options) { {} }

  define_method :build_publisher do
    builder =
      instance_double(Ephesus::Core::Scenes::Builder, type: 'spec.other')

    described_class.new(builder)
  end

  example_class 'Spec::Subscriber' do |klass|
    klass.define_method(:receive_message) { |_| nil }
  end

  describe '::BuildError' do
    include_examples 'should define constant',
      :BuildError,
      -> { be_a(Class).and(be < StandardError) }
  end

  describe '::SceneAdded' do
    let(:expected) { %i[scene type] }

    include_examples 'should define constant',
      :SceneAdded,
      -> { be_a(Class).and(be < Ephesus::Core::Message) }

    it { expect(described_class::SceneAdded.members).to be == expected }
  end

  describe '.subclass' do
    it 'should define the class method' do
      expect(described_class)
        .to respond_to(:subclass)
        .with_unlimited_arguments
        .and_any_keywords
        .and_a_block
    end
  end

  include_deferred 'should publish messages'

  describe '#initialize' do
    it 'should define the constructor' do
      expect(described_class)
        .to be_constructible
        .with(1).argument
        .and_keywords(:type)
        .and_any_keywords
    end
  end

  describe '#builder' do
    include_examples 'should define reader', :builder, -> { builder }
  end

  describe '#get' do
    let(:scene)    { Ephesus::Core::Scene.new }
    let(:result)   { Cuprum::Result.new(value: scene) }
    let(:observer) { Spec::Subscriber.new }
    let(:matching) { nil }
    let(:message)  { described_class::SceneAdded.new(scene:, type: pool.type) }

    before(:example) do
      allow(builder).to receive(:call).and_return(result)

      add_matching_scene

      allow(observer).to receive(:receive_message)

      pool.add_subscription(observer, channel: :scene_added)
    end

    define_method :add_matching_scene do
      matching
    end

    it 'should define the method' do
      expect(pool)
        .to respond_to(:get)
        .with(0).arguments
        .and_any_keywords
    end

    it 'should call the builder' do
      pool.get

      expect(builder).to have_received(:call).with(no_args)
    end

    it { expect(pool.get).to be scene }

    it 'should publish the message on channel :scene_added' do
      pool.get

      expect(observer).to have_received(:receive_message).with(be == message)
    end

    context 'when the builder returns a failing result' do
      let(:error) { Cuprum::Error.new(message: 'something went wrong') }
      let(:error_message) do
        'unable to build scene - something went wrong'
      end

      before(:example) do
        allow(builder)
          .to receive(:call)
          .and_return(Cuprum::Result.new(error:))
      end

      it 'should raise an exception' do
        expect { pool.get }
          .to raise_error described_class::BuildError, error_message
      end
    end

    context 'when the pool has a non-matching scene' do
      let(:other_options) { { difficulty: :hard, ironman: true } }
      let(:other_scene)   { Ephesus::Core::Scene.new }

      before(:example) do
        allow(builder)
          .to receive(:call)
          .with(**other_options)
          .and_return(Cuprum::Result.new(value: other_scene))

        pool.get(difficulty: :hard, ironman: true)
      end

      it 'should call the builder' do
        pool.get

        expect(builder).to have_received(:call).with(no_args)
      end

      it { expect(pool.get).to be scene }

      it 'should publish the message on channel :scene_added' do
        pool.get

        expect(observer).to have_received(:receive_message).with(be == message)
      end
    end

    context 'when the pool has a matching scene' do
      let(:matching) { pool.get }

      before(:example) do
        allow(builder)
          .to receive(:call)
          .and_return(
            Cuprum::Result.new(value: Ephesus::Core::Scene.new)
          )
      end

      it 'should not call the builder again' do
        pool.get

        expect(builder).to have_received(:call).exactly(1).times.with(no_args)
      end

      it { expect(pool.get).to be scene }

      it 'should not publish the message' do
        pool.get

        expect(observer).not_to have_received(:receive_message)
      end
    end

    describe 'with options: value' do
      let(:options) { { difficulty: :medium, debug_mode: true } }

      it 'should call the builder' do
        pool.get(**options)

        expect(builder).to have_received(:call).with(**options)
      end

      it { expect(pool.get(**options)).to be scene }

      it 'should publish the message on channel :scene_added' do
        pool.get(**options)

        expect(observer).to have_received(:receive_message).with(be == message)
      end

      context 'when the builder returns a failing result' do
        let(:error) { Cuprum::Error.new(message: 'something went wrong') }
        let(:error_message) do
          "unable to build scene with options #{options.inspect} - something " \
            'went wrong'
        end

        before(:example) do
          allow(builder)
            .to receive(:call)
            .and_return(Cuprum::Result.new(error:))
        end

        it 'should raise an exception' do
          expect { pool.get(**options) }
            .to raise_error described_class::BuildError, error_message
        end
      end

      context 'when the pool has a non-matching scene' do
        let(:other_options) { { difficulty: :hard, ironman: true } }
        let(:other_scene)   { Ephesus::Core::Scene.new }

        before(:example) do
          allow(builder)
            .to receive(:call)
            .with(**other_options)
            .and_return(Cuprum::Result.new(value: other_scene))

          pool.get(difficulty: :hard, ironman: true)
        end

        it 'should call the builder' do
          pool.get(**options)

          expect(builder).to have_received(:call).with(**options)
        end

        it { expect(pool.get(**options)).to be scene }

        it 'should publish the message on channel :scene_added' do
          pool.get(**options)

          expect(observer)
            .to have_received(:receive_message)
            .with(be == message)
        end
      end

      context 'when the pool has a matching scene' do
        let(:matching) { pool.get(**options) }

        before(:example) do
          allow(builder)
            .to receive(:call)
            .and_return(
              Cuprum::Result.new(value: Ephesus::Core::Scene.new)
            )
        end

        it 'should not call the builder again' do
          pool.get(**options)

          expect(builder)
            .to have_received(:call)
            .exactly(1).times
            .with(**options)
        end

        it { expect(pool.get(**options)).to be scene }

        it 'should not publish the message' do
          pool.get(**options)

          expect(observer).not_to have_received(:receive_message)
        end
      end
    end

    context 'when multiple threads request a scene' do
      let(:values) { [] }
      let(:threads) do
        Array.new(3) do |index|
          Thread.new { values[index] = pool.get }
        end
      end

      before(:example) do
        scenes = [scene, Ephesus::Core::Scene.new, Ephesus::Core::Scene.new]

        allow(builder).to receive(:call) do
          sleep 1

          Cuprum::Result.new(value: scenes.shift)
        end
      end

      it 'should not generate multiple scenes', :aggregate_failures do
        threads.map(&:join)

        expect(values.size).to be 3
        expect(values).to all be scene
      end
    end
  end

  describe '#options' do
    include_examples 'should define reader', :options, {}

    context 'when initialized with options: value' do
      let(:options) { { custom_option: 'custom value', password: 'password' } }

      it { expect(pool.options).to be == options }
    end

    context 'when initialized with type: value' do
      let(:type)    { 'spec.example' }
      let(:options) { super().merge(type:) }

      it { expect(pool.options).to be == options.except(:type) }
    end

    context 'with a subclass with static options' do
      let(:static_options) do
        { custom_option: 'static_value', secret: '12345' }
      end
      let(:described_class) do
        super().subclass(**static_options)
      end

      it { expect(pool.options).to be == static_options }

      context 'when initialized with options: value' do
        let(:options) do
          { custom_option: 'custom value', password: 'password' }
        end
        let(:expected) { static_options.merge(options) }

        it { expect(pool.options).to be == expected }
      end
    end
  end

  describe '#type' do
    include_examples 'should define reader', :type, -> { builder.type }

    context 'when initialized with type: value' do
      let(:type)    { 'spec.example' }
      let(:options) { super().merge(type:) }

      it { expect(pool.type).to be == type }
    end
  end
end
