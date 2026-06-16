# frozen_string_literal: true

require 'ephesus/core/formats/plain_text/errors/template_not_found'

RSpec.describe Ephesus::Core::Formats::PlainText::Errors::TemplateNotFound do
  subject(:error) { described_class.new(notification:, **options) }

  let(:actor)        { Ephesus::Core::Actor.new }
  let(:notification) { Spec::CustomNotification.new(original_actor: actor) }
  let(:options)      { {} }

  example_constant 'Spec::CustomNotification' do
    Ephesus::Core::Messages::Notification.define
  end

  describe '::TYPE' do
    let(:expected) do
      'ephesus.core.formats.plain_text.errors.template_not_found'
    end

    it 'should define the constant' do
      expect(described_class).to define_constant(:TYPE).with_value(expected)
    end
  end

  describe '.new' do
    it 'should define the constructor' do
      expect(described_class)
        .to be_constructible
        .with(0).arguments
        .and_keywords(:details, :expected_key, :notification)
    end
  end

  describe '#as_json' do
    let(:expected) do
      {
        'data'    => {
          'expected_key' => error.expected_key,
          'notification' => notification.as_json
        },
        'message' => error.message,
        'type'    => error.type
      }
    end

    include_examples 'should have reader', :as_json, -> { be == expected }

    context 'when initialized with details: value' do
      let(:details) { 'something went wrong' }
      let(:options) { super().merge(details:) }
      let(:expected) do
        {
          'data'    => {
            'details'      => details,
            'expected_key' => notification.type,
            'notification' => notification.as_json
          },
          'message' => error.message,
          'type'    => error.type
        }
      end

      it { expect(error.as_json).to be == expected }
    end

    context 'when initialized with expected_key: value' do
      let(:expected_key) { 'spec.custom_key' }
      let(:options)      { super().merge(expected_key:) }

      it { expect(error.as_json).to be == expected }
    end
  end

  describe '#details' do
    include_examples 'should define reader', :details, nil

    context 'when initialized with details: value' do
      let(:details) { 'something went wrong' }
      let(:options) { super().merge(details:) }

      it { expect(error.details).to be == details }
    end
  end

  describe '#expected_key' do
    include_examples 'should define reader',
      :expected_key,
      -> { notification.type }

    context 'when initialized with expected_key: value' do
      let(:expected_key) { 'spec.custom_key' }
      let(:options)      { super().merge(expected_key:) }

      it { expect(error.expected_key).to be == expected_key }
    end
  end

  describe '#message' do
    let(:expected) do
      "template not found for message #{notification.type.inspect}"
    end

    include_examples 'should define reader', :message, -> { expected }

    context 'when initialized with details: value' do
      let(:details)  { 'something went wrong' }
      let(:options)  { super().merge(details:) }
      let(:expected) { "#{super()} - #{details}" }

      it { expect(error.message).to be == expected }
    end

    context 'when initialized with expected_key: value' do
      let(:expected_key) { 'spec.custom_key' }
      let(:options)      { super().merge(expected_key:) }
      let(:expected) do
        "template not found for message #{expected_key.inspect}"
      end

      it { expect(error.message).to be == expected }
    end
  end

  describe '#notification' do
    include_examples 'should define reader', :notification, -> { notification }
  end

  describe '#type' do
    include_examples 'should define reader', :type, described_class::TYPE
  end
end
