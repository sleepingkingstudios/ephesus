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
    let(:event) { Spec::CustomEvent.new(ok: true) }
    let(:expected_error) do
      Ephesus::Core::Formats::Errors::UnhandledEvent.new(event:, scene:)
    end

    example_constant 'Spec::CustomEvent' do
      Ephesus::Core::Message.define(:ok)
    end

    it { expect(command).to be_callable.with(1).argument }

    describe 'with an unhandled event' do
      let(:event) { Ephesus::Core::Message.new }

      it 'should return a failing result' do
        expect(command.call(event))
          .to be_a_failing_result
          .with_error(expected_error)
      end
    end

    context 'when the scene handles events' do
      let(:scene) { Spec::CustomScene.new }

      example_class 'Spec::CustomCommand', Ephesus::Core::Command

      example_class 'Spec::CustomScene', Ephesus::Core::Scene do |klass|
        klass.handle_event Spec::CustomCommand, event_type: Spec::CustomEvent
      end

      describe 'with an unhandled event' do
        let(:event) { Ephesus::Core::Message.new }

        it 'should return a failing result' do
          expect(command.call(event))
            .to be_a_failing_result
            .with_error(expected_error)
        end
      end

      describe 'with a handled event' do
        let(:expected_value) { event }

        it 'should return a passing result' do
          expect(command.call(event))
            .to be_a_passing_result
            .with_value(expected_value)
        end
      end
    end

    context 'with a subclass that formats input messages' do
      let(:described_class) { Spec::FormatInput }

      # rubocop:disable RSpec/DescribedClass
      example_class 'Spec::FormatInput',
        Ephesus::Core::Formats::Commands::FormatInput \
      do |klass|
        klass.define_method :format_input do |input_message|
          return super(input_message) unless input_message.respond_to?(:ok)

          return Spec::FormattedInput.new if input_message.ok

          message = 'Input message not OK.'
          failure(Cuprum::Error.new(message:))
        end
      end
      # rubocop:enable RSpec/DescribedClass

      example_constant 'Spec::FormattedInput' do
        Ephesus::Core::Message.define
      end

      context 'when the input formatting returns a failing result' do
        let(:event) { Spec::CustomEvent.new(ok: false) }
        let(:expected_error) do
          Cuprum::Error.new(message: 'Input message not OK.')
        end

        it 'should return a failing result' do
          expect(command.call(event))
            .to be_a_failing_result
            .with_error(expected_error)
        end
      end

      describe 'with an unhandled event' do
        let(:event) { Ephesus::Core::Message.new }

        it 'should return a failing result' do
          expect(command.call(event))
            .to be_a_failing_result
            .with_error(expected_error)
        end
      end

      context 'when the scene handles events' do
        let(:scene) { Spec::CustomScene.new }

        example_class 'Spec::CustomCommand', Ephesus::Core::Command

        example_class 'Spec::CustomScene', Ephesus::Core::Scene do |klass|
          klass.handle_event Spec::CustomCommand,
            event_type: Spec::FormattedInput
        end

        describe 'with an unhandled event' do
          let(:event) { Ephesus::Core::Message.new }

          it 'should return a failing result' do
            expect(command.call(event))
              .to be_a_failing_result
              .with_error(expected_error)
          end
        end

        describe 'with a handled event' do
          let(:expected_value) { Spec::FormattedInput.new }

          it 'should return a passing result' do
            expect(command.call(event))
              .to be_a_passing_result
              .with_value(expected_value)
          end
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
