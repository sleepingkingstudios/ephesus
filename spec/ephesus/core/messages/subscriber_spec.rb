# frozen_string_literal: true

require 'ephesus/core/messages/subscriber'
require 'ephesus/core/rspec/deferred/messages_examples'

RSpec.describe Ephesus::Core::Messages::Subscriber do
  include Ephesus::Core::RSpec::Deferred::MessagesExamples

  subject(:subscriber) { described_class.new }

  let(:described_class) { Spec::Subscriber }

  example_class 'Spec::Publisher' do |klass|
    klass.include Ephesus::Core::Messages::Publisher
  end

  example_class 'Spec::Subscriber' do |klass|
    klass.include Ephesus::Core::Messages::Subscriber # rubocop:disable RSpec/DescribedClass
  end

  include_deferred 'should subscribe to messages'
end
