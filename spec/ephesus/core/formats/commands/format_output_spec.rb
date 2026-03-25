# frozen_string_literal: true

require 'ephesus/core/formats/commands/format_output'
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
  end

  describe '#options' do
    include_examples 'should define reader', :options, {}

    context 'when initialized with options' do
      let(:options) { super().merge(custom: 'value') }

      it { expect(command.options).to be == options }
    end
  end
end
