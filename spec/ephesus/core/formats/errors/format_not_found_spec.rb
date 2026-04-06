# frozen_string_literal: true

require 'ephesus/core/formats/errors/format_not_found'

RSpec.describe Ephesus::Core::Formats::Errors::FormatNotFound do
  subject(:error) { described_class.new(format:, **options) }

  let(:format)  { 'spec.format' }
  let(:options) { {} }

  describe '::TYPE' do
    let(:expected) { 'ephesus.core.formats.errors.format_not_found' }

    it 'should define the constant' do
      expect(described_class).to define_constant(:TYPE).with_value(expected)
    end
  end

  describe '.new' do
    it 'should define the constructor' do
      expect(described_class)
        .to be_constructible
        .with(0).arguments
        .and_keywords(:format, :message, :valid_formats)
    end
  end

  describe '#as_json' do
    let(:expected) do
      {
        'data'    => { 'format' => format, 'valid_formats' => [] },
        'message' => error.message,
        'type'    => error.type
      }
    end

    include_examples 'should have reader', :as_json, -> { be == expected }
  end

  describe '#format' do
    include_examples 'should define reader', :format, -> { format }
  end

  describe '#message' do
    let(:expected) { "format not found with type #{format.inspect}" }

    include_examples 'should define reader', :message, -> { expected }

    context 'when initialized with message: value' do
      let(:message)  { 'Something went wrong' }
      let(:options)  { super().merge(message:) }
      let(:expected) { "#{message} - #{super()}" }

      it { expect(error.message).to be == expected }
    end

    context 'when initialized with valid_formats: value' do
      let(:valid_formats) { %w[spec.coptic spec.demotic spec.hieroglyphic] }
      let(:options)       { super().merge(valid_formats:) }
      let(:expected) do
        formats = '"spec.coptic", "spec.demotic", "spec.hieroglyphic"'

        "#{super()} (valid formats are #{formats})"
      end

      it { expect(error.message).to be == expected }

      context 'when initialized with message: value' do
        let(:message)  { 'Something went wrong' }
        let(:options)  { super().merge(message:) }
        let(:expected) { "#{message} - #{super()}" }

        it { expect(error.message).to be == expected }
      end
    end
  end

  describe '#valid_formats' do
    include_examples 'should define reader', :valid_formats, []

    context 'when initialized with valid_formats: value' do
      let(:valid_formats) { %w[spec.coptic spec.demotic spec.hieroglyphic] }
      let(:options)       { super().merge(valid_formats:) }

      it { expect(error.valid_formats).to be == valid_formats }
    end
  end
end
