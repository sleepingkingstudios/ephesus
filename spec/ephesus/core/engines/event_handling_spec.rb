# frozen_string_literal: true

require 'ephesus/core/engines/event_handling'
require 'ephesus/core/rspec/deferred/engines_examples'

RSpec.describe Ephesus::Core::Engines::EventHandling do
  include Ephesus::Core::RSpec::Deferred::EnginesExamples

  subject(:engine) { described_class.new }

  let(:described_class) { Spec::CustomEngine }

  example_class 'Spec::CustomEngine' do |klass|
    klass.include Ephesus::Core::Engines::EventHandling # rubocop:disable RSpec/DescribedClass
  end

  include_deferred 'should implement the event handling interface'

  include_deferred 'should implement the event handling methods'
end
