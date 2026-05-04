# frozen_string_literal: true

require 'ephesus/core/formats/plain_text/error_message'

RSpec.describe Ephesus::Core::Formats::PlainText::ErrorMessage do
  subject(:error_message) { described_class.new(**options) }

  let(:format)  { 'spec.custom_format' }
  let(:error)   { Cuprum::Error.new(message: 'Something went wrong.') }
  let(:text)    { 'Cuprum::Error: Something went wrong' }
  let(:options) { { error:, format:, text: } }

  describe '.new' do
    let(:expected_keywords) do
      %i[details error error_id format message text]
    end

    it 'should define the constructor' do
      expect(described_class)
        .to be_constructible
        .with(0).arguments
        .and_keywords(*expected_keywords)
    end
  end

  describe '.members' do
    let(:expected) { %i[format error error_id message details text] }

    it { expect(described_class.members).to be == expected }
  end

  describe '#details' do
    include_examples 'should define reader', :details, {}

    context 'when initialized with details' do
      let(:details) { { password: 'password', secret: 12_345 } }
      let(:options) { super().merge(details:) }

      it { expect(error_message.details).to be == details }
    end
  end

  describe '#error' do
    include_examples 'should define reader', :error, -> { error }
  end

  describe '#error_id' do
    let(:expected_format) { /\A\h{8}-\h{4}-\h{4}-\h{4}-\h{12}\z/ }

    include_examples 'should define reader',
      :error_id,
      -> { be_a(String).and match(expected_format) }

    context 'when initialized with an error ID' do
      let(:error_id) { '12345' }
      let(:options)  { super().merge(error_id:) }

      it { expect(error_message.error_id).to be == error_id }
    end
  end

  describe '#format' do
    include_examples 'should define reader', :format, -> { format }
  end

  describe '#message' do
    include_examples 'should define reader', :message, -> { error.message }

    context 'when initialized with message: value' do
      let(:message) { 'Reactor temperature critical.' }
      let(:options) { super().merge(message:) }

      it { expect(error_message.message).to be == message }
    end
  end

  describe '#text' do
    include_examples 'should define reader', :text, -> { text }
  end
end
