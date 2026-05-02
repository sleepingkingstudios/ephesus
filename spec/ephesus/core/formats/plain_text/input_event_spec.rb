# frozen_string_literal: true

require 'ephesus/core/formats/plain_text/input_event'

RSpec.describe Ephesus::Core::Formats::PlainText::InputEvent do
  subject(:message) { described_class.new(**options) }

  let(:text)    { 'Greetings, programs!' }
  let(:options) { { text: } }

  describe '.new' do
    it 'should define the constructor' do
      expect(described_class)
        .to be_constructible
        .with(0).arguments
        .and_keywords(:connection, :format, :text)
    end
  end

  describe '.members' do
    it { expect(described_class.members).to be == %i[connection format text] }
  end

  describe '#connection' do
    include_examples 'should define reader', :connection, nil

    context 'when initialized with connection: value' do
      let(:connection) do
        Ephesus::Core::Connection.new(format: 'spec.example_format')
      end
      let(:options) { super().merge(connection:) }

      it { expect(message.connection).to be connection }
    end

    context 'with a connection' do
      let(:connection) do
        Ephesus::Core::Connection.new(format: 'spec.example_format')
      end

      it { expect(message.with(connection:).connection).to be connection }
    end
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
