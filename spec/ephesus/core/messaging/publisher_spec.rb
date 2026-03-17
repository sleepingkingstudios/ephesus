# frozen_string_literal: true

require 'ephesus/core/messaging/publisher'
require 'ephesus/core/rspec/deferred/messages_examples'

RSpec.describe Ephesus::Core::Messaging::Publisher do
  include Ephesus::Core::RSpec::Deferred::MessagesExamples

  subject(:publisher) { described_class.new }

  let(:described_class) { Spec::Publisher }

  example_class 'Spec::Publisher' do |klass|
    klass.include Ephesus::Core::Messaging::Publisher # rubocop:disable RSpec/DescribedClass
  end

  example_class 'Spec::Subscriber' do |klass|
    klass.define_method(:receive_message) { |_| nil }
  end

  describe '::ALL_CHANNELS' do
    let(:expected) do
      '#<Ephesus::Core::Messaging::Publisher::AllChannels>'
    end

    include_examples 'should define constant', :ALL_CHANNELS

    it { expect(described_class::ALL_CHANNELS.inspect).to be == expected }
  end

  include_deferred 'should publish messages'
end
