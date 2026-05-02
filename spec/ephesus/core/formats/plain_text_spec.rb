# frozen_string_literal: true

require 'ephesus/core/formats/plain_text'

RSpec.describe Ephesus::Core::Formats::PlainText do
  describe '.type' do
    include_examples 'should define class reader',
      :type,
      'ephesus.core.formats.plain_text'
  end
end
