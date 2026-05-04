# frozen_string_literal: true

require 'ephesus/core/formats/commands/format_output'
require 'ephesus/core/messages/error_notification'
require 'ephesus/core/messages/notification'

RSpec.describe Ephesus::Core::Formats::Commands::FormatOutput do
  subject(:command) { described_class.new(**options) }

  let(:options) { {} }

  describe '.new' do
    it 'should define the constructor' do
      expect(described_class)
        .to be_constructible
        .with(0).arguments
        .and_any_keywords
    end
  end

  describe '#call' do
    let(:actor) { Ephesus::Core::Actor.new }
    let(:notification) do
      Ephesus::Core::Messages::Notification.new(original_actor: actor)
    end
    let(:expected_error) do
      Ephesus::Core::Formats::Errors::UnhandledNotification.new(notification:)
    end

    it { expect(command).to be_callable.with(1).argument }

    describe 'with an unhandled notification' do
      it 'should return a failing result' do
        expect(command.call(notification))
          .to be_a_failing_result
          .with_error(expected_error)
      end
    end

    describe 'with an error notification' do
      let(:message) { 'Something went wrong.' }
      let(:error)   { Cuprum::Error.new(message:) }
      let(:notification) do
        Ephesus::Core::Messages::ErrorNotification
          .new(original_actor: actor, error:)
      end
      let(:expected_value) do
        Ephesus::Core::Formats::ErrorMessage.new(
          details:  notification.details,
          error:    notification.error,
          error_id: notification.error_id,
          format:   command.format,
          message:  notification.message
        )
      end

      it 'should return a passing result' do
        expect(command.call(notification))
          .to be_a_passing_result
          .with_value(expected_value)
      end

      describe 'with error options' do
        let(:details)  { { password: 'password', secret: '12345' } }
        let(:error_id) { SecureRandom.uuid }
        let(:notification) do
          Ephesus::Core::Messages::ErrorNotification
            .new(original_actor: actor, details:, error:, error_id:)
        end

        it 'should return a passing result' do
          expect(command.call(notification))
            .to be_a_passing_result
            .with_value(expected_value)
        end
      end
    end

    context 'with a subclass that formats output messages' do
      let(:described_class) { Spec::FormatOutput }

      # rubocop:disable RSpec/DescribedClass
      example_class 'Spec::FormatOutput',
        Ephesus::Core::Formats::Commands::FormatOutput \
      do |klass|
        klass.define_method :format_output do |notification|
          return Spec::FormattedOutput.new if notification.original_actor

          message = 'Actor not found.'
          failure(Cuprum::Error.new(message:))
        end
      end
      # rubocop:enable RSpec/DescribedClass

      example_constant 'Spec::FormattedOutput' do
        Ephesus::Core::Message.define
      end

      context 'when the output formatting returns a failing result' do
        let(:notification) do
          Ephesus::Core::Messages::Notification.new(original_actor: nil)
        end
        let(:expected_error) do
          Cuprum::Error.new(message: 'Actor not found.')
        end

        it 'should return a failing result' do
          expect(command.call(notification))
            .to be_a_failing_result
            .with_error(expected_error)
        end
      end

      context 'when the output formatting returns a passing result' do
        let(:expected_value) { Spec::FormattedOutput.new }

        it 'should return a passing result' do
          expect(command.call(notification))
            .to be_a_passing_result
            .with_value(expected_value)
        end
      end
    end
  end

  describe '#format' do
    let(:expected) { Ephesus::Core::Formats::DEFAULT_FORMAT }

    include_examples 'should define reader', :format, -> { expected }

    context 'when initialized with format: value' do
      let(:format)  { 'spec.custom_format' }
      let(:options) { super().merge(format:) }

      it { expect(command.format).to be == format }
    end
  end

  describe '#options' do
    include_examples 'should define reader', :options, {}

    context 'when initialized with options' do
      let(:options) { super().merge(custom: 'value') }

      it { expect(command.options).to be == options }
    end
  end
end
