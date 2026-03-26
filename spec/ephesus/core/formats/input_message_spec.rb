# frozen_string_literal: true

require 'ephesus/core/formats/input_message'

RSpec.describe Ephesus::Core::Formats::InputMessage do
  subject(:message) { described_class.new(**options) }

  let(:format)  { 'spec.custom_format' }
  let(:options) { { format: } }

  describe '.new' do
    it 'should define the constructor' do
      expect(described_class)
        .to be_constructible
        .with(0).arguments
        .and_keywords(:connection, :format)
    end
  end

  describe '.members' do
    it { expect(described_class.members).to be == %i[connection format] }
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
    include_examples 'should define reader', :format, -> { format }
  end
end
