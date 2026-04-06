# frozen_string_literal: true

require 'ephesus/core/engines/errors/missing_actor'

RSpec.describe Ephesus::Core::Engines::Errors::MissingActor do
  subject(:error) { described_class.new(**options) }

  let(:options) { {} }

  describe '::TYPE' do
    let(:expected) { 'ephesus.core.engines.errors.missing_actor' }

    it 'should define the constant' do
      expect(described_class).to define_constant(:TYPE).with_value(expected)
    end
  end

  describe '.new' do
    it 'should define the constructor' do
      expect(described_class)
        .to be_constructible
        .with(0).arguments
        .and_keywords(:message)
    end
  end

  describe '#as_json' do
    let(:expected) do
      {
        'data'    => {},
        'message' => error.message,
        'type'    => error.type
      }
    end

    include_examples 'should have reader', :as_json, -> { be == expected }
  end

  describe '#message' do
    let(:expected) { 'connection does not have an actor' }

    include_examples 'should define reader', :message, -> { be == expected }

    context 'when initialized with message: value' do
      let(:message)  { 'Something went wrong' }
      let(:options)  { super().merge(message:) }
      let(:expected) { "#{message} - #{super()}" }

      it { expect(error.message).to be == expected }
    end
  end

  describe '#type' do
    include_examples 'should define reader', :type, described_class::TYPE
  end
end
