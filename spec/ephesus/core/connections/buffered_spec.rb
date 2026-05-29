# frozen_string_literal: true

require 'ephesus/core/connection'
require 'ephesus/core/connections/buffered'

RSpec.describe Ephesus::Core::Connections::Buffered do
  subject(:connection) { described_class.new(format:) }

  let(:described_class) { Spec::BufferedConnection }
  let(:format)          { 'spec.example_format' }

  example_class 'Spec::BufferedConnection', Ephesus::Core::Connection do |klass|
    klass.include Ephesus::Core::Connections::Buffered # rubocop:disable RSpec/DescribedClass
  end

  describe '#empty_buffer?' do
    include_examples 'should define predicate', :empty_buffer?, true

    context 'when the connection has received output messages' do
      let(:messages) do
        Array.new(3) { Ephesus::Core::Message.new }
      end

      before(:example) do
        messages.each do |message|
          connection.publish(message, channel: :output)
        end
      end

      it { expect(connection.empty_buffer?).to be false }
    end
  end

  describe '#flush_buffer' do
    it { expect(connection).to respond_to(:flush_buffer).with(0).arguments }

    it { expect(connection.flush_buffer).to be == [] }

    context 'when the connection has received output messages' do
      let(:messages) do
        Array.new(3) { Ephesus::Core::Message.new }
      end

      before(:example) do
        messages.each do |message|
          connection.publish(message, channel: :output)
        end
      end

      it { expect(connection.flush_buffer).to be == messages }

      it 'should empty the buffer' do
        expect { connection.flush_buffer }
          .to change(connection, :empty_buffer?)
          .to be true
      end
    end
  end
end
