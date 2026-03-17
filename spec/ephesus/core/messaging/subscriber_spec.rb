# frozen_string_literal: true

require 'ephesus/core/messaging/subscriber'
require 'ephesus/core/rspec/deferred/messages_examples'

RSpec.describe Ephesus::Core::Messaging::Subscriber do
  include Ephesus::Core::RSpec::Deferred::MessagesExamples

  subject(:subscriber) { described_class.new }

  let(:described_class) { Spec::Subscriber }

  example_class 'Spec::Publisher' do |klass|
    klass.include Ephesus::Core::Messaging::Publisher
  end

  example_class 'Spec::Subscriber' do |klass|
    klass.include Ephesus::Core::Messaging::Subscriber # rubocop:disable RSpec/DescribedClass
  end

  include_deferred 'should subscribe to messages'
end
