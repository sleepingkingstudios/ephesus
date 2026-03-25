# frozen_string_literal: true

require 'ephesus/core/formats/errors/output_error'

RSpec.describe Ephesus::Core::Formats::Errors::OutputError do
  subject(:error) { described_class.new(message:, notification:) }

  let(:message)      { 'Something went wrong.' }
  let(:notification) { Spec::CustomNotification.new }

  example_constant 'Spec::CustomNotification' do
    Ephesus::Core::Message.define
  end

  describe '::TYPE' do
    let(:expected) { 'ephesus.core.formats.errors.output_error' }

    it 'should define the constant' do
      expect(described_class).to define_constant(:TYPE).with_value(expected)
    end
  end

  describe '.new' do
    it 'should define the constructor' do
      expect(described_class)
        .to be_constructible
        .with(0).arguments
        .and_keywords(:message, :notification)
    end
  end

  describe '#as_json' do
    let(:expected) do
      {
        'data'    => { 'notification' => notification.as_json },
        'message' => error.message,
        'type'    => error.type
      }
    end

    include_examples 'should have reader', :as_json, -> { be == expected }
  end

  describe '#message' do
    include_examples 'should define reader', :message, -> { message }
  end

  describe '#notification' do
    include_examples 'should define reader', :notification, -> { notification }
  end

  describe '#type' do
    include_examples 'should define reader', :type, described_class::TYPE
  end
end
