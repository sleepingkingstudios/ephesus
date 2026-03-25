# frozen_string_literal: true

require 'ephesus/core/formats/formatter'
require 'ephesus/core/messages/notification'

RSpec.describe Ephesus::Core::Formats::Formatter do
  subject(:formatter) { described_class.new }

  let(:described_class) { Spec::Formatter }

  example_class 'Spec::Formatter' do |klass|
    klass.include Ephesus::Core::Formats::Formatter # rubocop:disable RSpec/DescribedClass
  end

  describe '.new' do
    it { expect(described_class).to be_constructible.with(0).arguments }
  end

  describe '#format_input' do
    let(:event) { Ephesus::Core::Message.new }
    let(:scene) { Ephesus::Core::Scene.new }
    let(:expected_error) do
      Ephesus::Core::Formats::Errors::UnhandledEvent.new(event:, scene:)
    end

    it 'should define the method' do
      expect(formatter)
        .to respond_to(:format_input)
        .with(0).arguments
        .and_keywords(:event, :scene)
        .and_any_keywords
    end

    describe 'with an unhandled event' do
      it 'should return a failing result' do
        expect(formatter.format_input(event:, scene:))
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
          expect(formatter.format_input(event:, scene:))
            .to be_a_failing_result
            .with_error(expected_error)
        end
      end

      describe 'with a handled event' do
        let(:event)          { Spec::CustomEvent.new }
        let(:expected_value) { event }

        it 'should return a passing result' do
          expect(formatter.format_input(event:, scene:))
            .to be_a_passing_result
            .with_value(expected_value)
        end
      end
    end

    context 'with a custom format command' do
      let(:expected_value) do
        Spec::InputEvent.new(ok: true)
      end

      example_class 'Spec::FormatInput',
        Ephesus::Core::Formats::Commands::FormatOutput \
      do |klass|
        klass.define_method(:process) do |_|
          Spec::InputEvent.new(ok: true)
        end
      end

      example_constant 'Spec::InputEvent' do
        Ephesus::Core::Message.define(:ok)
      end

      before(:example) do
        described_class.class_eval do
          def input_formatter_for(**) = Spec::FormatInput.new(**)
        end
      end

      it 'should return a passing result' do
        expect(formatter.format_input(event:, scene:))
          .to be_a_passing_result
          .with_value(expected_value)
      end
    end
  end

  describe '#format_output' do
    let(:actor) { Ephesus::Core::Actor.new }
    let(:notification) do
      Ephesus::Core::Messages::Notification.new(original_actor: actor)
    end
    let(:expected_error) do
      Ephesus::Core::Formats::Errors::UnhandledNotification.new(notification:)
    end

    it 'should define the method' do
      expect(formatter)
        .to respond_to(:format_output)
        .with(0).arguments
        .and_keywords(:notification)
        .and_any_keywords
    end

    describe 'with an unhandled notification' do
      it 'should return a failing result' do
        expect(formatter.format_output(notification:))
          .to be_a_failing_result
          .with_error(expected_error)
      end
    end

    context 'with a custom format command' do
      let(:expected_value) do
        Spec::OutputMessage.new(ok: true)
      end

      example_class 'Spec::FormatOutput',
        Ephesus::Core::Formats::Commands::FormatOutput \
      do |klass|
        klass.define_method(:process) do |_|
          Spec::OutputMessage.new(ok: true)
        end
      end

      example_constant 'Spec::OutputMessage' do
        Ephesus::Core::Message.define(:ok)
      end

      before(:example) do
        described_class.class_eval do
          def output_formatter_for(**) = Spec::FormatOutput.new(**)
        end
      end

      it 'should return a passing result' do
        expect(formatter.format_output(notification:))
          .to be_a_passing_result
          .with_value(expected_value)
      end
    end
  end
end
