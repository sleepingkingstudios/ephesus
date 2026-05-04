# frozen_string_literal: true

require 'ephesus/core/formats/plain_text/output_message'

RSpec.describe Ephesus::Core::Formats::PlainText::OutputMessage do
  subject(:message) { described_class.new(**options) }

  let(:format)  { 'spec.custom_format' }
  let(:text)    { 'Greetings, programs!' }
  let(:options) { { text: } }

  describe '.new' do
    it 'should define the constructor' do
      expect(described_class)
        .to be_constructible
        .with(0).arguments
        .and_keywords(:format, :text)
    end
  end

  describe '.members' do
    it { expect(described_class.members).to be == %i[format text] }
  end

  describe '#format' do
    let(:expected) do
      Ephesus::Core::Formats::PlainText.type
    end

    include_examples 'should define reader', :format, -> { expected }

    context 'when initialized with connection: value' do
      let(:format)  { 'spec.example_format' }
      let(:options) { super().merge(format:) }

      it { expect(message.format).to be == format }
    end
  end

  describe '#text' do
    include_examples 'should define reader', :text, -> { text }
  end
end
