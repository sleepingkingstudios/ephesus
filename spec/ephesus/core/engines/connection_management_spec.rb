# frozen_string_literal: true

require 'ephesus/core/engines/connection_management'
require 'ephesus/core/rspec/deferred/engines_examples'
require 'ephesus/core/rspec/deferred/messages_examples'

RSpec.describe Ephesus::Core::Engines::ConnectionManagement do
  include Ephesus::Core::RSpec::Deferred::EnginesExamples
  include Ephesus::Core::RSpec::Deferred::MessagesExamples

  subject(:engine) { described_class.new }

  let(:described_class) { Spec::CustomEngine }

  example_class 'Spec::CustomEngine' do |klass|
    klass.include Ephesus::Core::Engines::ConnectionManagement # rubocop:disable RSpec/DescribedClass
  end

  example_class 'Spec::Publisher' do |klass|
    klass.include Ephesus::Core::Messaging::Publisher
  end

  describe '::ConnectionError' do
    include_examples 'should define constant',
      :ConnectionError,
      -> { be_a(Class).and(be < StandardError) }
  end

  describe '.new' do
    it 'should define the constructor' do
      expect(described_class)
        .to be_constructible
        .with(0).arguments
        .and_any_keywords
    end
  end

  include_deferred 'should subscribe to messages'

  include_deferred 'should implement the connection management interface'

  include_deferred 'should implement the connection management methods'

  describe '#build_actor' do
    let(:connection) { Ephesus::Core::Connection.new(format: 'spec.format') }
    let(:actor)      { subject.send(:build_actor, connection) }

    it { expect(actor).to be_a Ephesus::Core::Actor }
  end
end
