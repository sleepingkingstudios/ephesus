# frozen_string_literal: true

require 'ephesus/core/formats/commands/format_input'
require 'ephesus/core/scene'

RSpec.describe Ephesus::Core::Formats::Commands::FormatInput do
  subject(:command) { described_class.new(scene:, **options) }

  let(:scene)   { Ephesus::Core::Scene.new }
  let(:options) { {} }

  describe '.new' do
    it 'should define the constructor' do
      expect(described_class)
        .to be_constructible
        .with(0).arguments
        .and_keywords(:scene)
        .and_any_keywords
    end
  end

  describe '#call' do
    let(:event) { Ephesus::Core::Message.new }
    let(:expected_error) do
      Ephesus::Core::Formats::Errors::UnhandledEvent.new(event:, scene:)
    end

    it { expect(command).to be_callable.with(1).argument }

    describe 'with an unhandled event' do
      it 'should return a failing result' do
        expect(command.call(event))
          .to be_a_failing_result
          .with_error(expected_error)
      end
    end

    context 'when the scene handles events' do
      let(:scene) { Spec::CustomScene.new }

      example_constant 'Spec::CustomEvent' do
        Ephesus::Core::Message.define
      end

      example_constant 'Spec::CustomCommand', Ephesus::Core::Command

      example_class 'Spec::CustomScene', Ephesus::Core::Scene do |klass|
        klass.handle_event Spec::CustomEvent, Spec::CustomCommand
      end

      describe 'with an unhandled event' do
        it 'should return a failing result' do
          expect(command.call(event))
            .to be_a_failing_result
            .with_error(expected_error)
        end
      end

      describe 'with a handled event' do
        let(:event)          { Spec::CustomEvent.new }
        let(:expected_value) { event }

        it 'should return a passing result' do
          expect(command.call(event))
            .to be_a_passing_result
            .with_value(expected_value)
        end
      end
    end
  end

  describe '#options' do
    include_examples 'should define reader', :options, {}

    context 'when initialized with options' do
      let(:options) { super().merge(custom: 'value') }

      it { expect(command.options).to be == options }
    end
  end

  describe '#scene' do
    include_examples 'should define reader', :scene, -> { scene }
  end
end
