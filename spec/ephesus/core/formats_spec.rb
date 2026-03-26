# frozen_string_literal: true

require 'ephesus/core/formats'

RSpec.describe Ephesus::Core::Formats do
  describe '::DEFAULT_FORMAT' do
    let(:expected) { 'ephesus.core.formats.generic' }

    include_examples 'should define immutable constant',
      :DEFAULT_FORMAT,
      -> { expected }
  end
end
