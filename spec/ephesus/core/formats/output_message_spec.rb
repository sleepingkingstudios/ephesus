# frozen_string_literal: true

require 'ephesus/core/formats/output_message'

RSpec.describe Ephesus::Core::Formats::OutputMessage do
  subject(:message) { described_class.new(**options) }

  let(:format)  { 'spec.custom_format' }
  let(:options) { { format: } }

  describe '.members' do
    it { expect(described_class.members).to be == %i[format] }
  end

  describe '#format' do
    include_examples 'should define reader', :format, -> { format }
  end
end
