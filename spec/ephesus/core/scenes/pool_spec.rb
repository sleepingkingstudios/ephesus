# frozen_string_literal: true

require 'ephesus/core/scene'
require 'ephesus/core/scenes/builder'
require 'ephesus/core/scenes/pool'

RSpec.describe Ephesus::Core::Scenes::Pool do
  subject(:pool) { described_class.new(builder) }

  let(:builder) { instance_double(Ephesus::Core::Scenes::Builder, call: nil) }

  describe '::BuildError' do
    include_examples 'should define constant',
      :BuildError,
      -> { be_a(Class).and(be < StandardError) }
  end

  describe '#initialize' do
    it { expect(described_class).to be_constructible.with(1).argument }
  end

  describe '#builder' do
    include_examples 'should define reader', :builder, -> { builder }
  end

  describe '#get' do
    let(:scene)  { Ephesus::Core::Scene.new }
    let(:result) { Cuprum::Result.new(value: scene) }

    before(:example) do
      allow(builder).to receive(:call).and_return(result)
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
    end

    context 'when the pool has a matching scene' do
      before(:example) do
        allow(builder)
          .to receive(:call)
          .with(no_args)
          .and_return(
            Cuprum::Result.new(value: scene),
            Cuprum::Result.new(value: Ephesus::Core::Scene.new)
          )

        pool.get
      end

      it 'should not call the builder again' do
        pool.get

        expect(builder).to have_received(:call).exactly(1).times.with(no_args)
      end

      it { expect(pool.get).to be scene }
    end

    describe 'with options: value' do
      let(:options) { { difficulty: :medium, debug_mode: true } }

      it 'should call the builder' do
        pool.get(**options)

        expect(builder).to have_received(:call).with(**options)
      end

      it { expect(pool.get(**options)).to be scene }

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
      end

      context 'when the pool has a matching scene' do
        before(:example) do
          allow(builder)
            .to receive(:call)
            .with(no_args)
            .and_return(
              Cuprum::Result.new(value: scene),
              Cuprum::Result.new(value: Ephesus::Core::Scene.new)
            )

          pool.get
        end

        it 'should call the builder' do
          pool.get(**options)

          expect(builder).to have_received(:call).with(**options)
        end

        it { expect(pool.get(**options)).to be scene }
      end
    end
  end
end
