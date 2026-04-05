# frozen_string_literal: true

require 'ephesus/core/engine'
require 'ephesus/core/rspec/deferred/engines_examples'
require 'ephesus/core/rspec/deferred/messages_examples'

RSpec.describe Ephesus::Core::Engine do
  include Ephesus::Core::RSpec::Deferred::EnginesExamples
  include Ephesus::Core::RSpec::Deferred::MessagesExamples

  subject(:engine) { described_class.new }

  deferred_context 'with an engine subclass' do
    let(:described_class) { Spec::CustomEngine }

    example_class 'Spec::CustomEngine', Ephesus::Core::Engine # rubocop:disable RSpec/DescribedClass
  end

  example_class 'Spec::Publisher' do |klass|
    klass.include Ephesus::Core::Messaging::Publisher
  end

  define_method :tools do
    SleepingKingStudios::Tools::Toolbelt.instance
  end

  include_deferred 'should subscribe to messages'

  include_deferred 'should implement the scene management interface'

  wrap_deferred 'with an engine subclass' do
    include_deferred 'should implement the scene management methods'
  end

  describe '.abstract?' do
    it { expect(described_class).to respond_to(:abstract?).with(0).arguments }

    it { expect(described_class.abstract?).to be true }

    wrap_deferred 'with an engine subclass' do
      it { expect(described_class.abstract?).to be false }
    end
  end

  describe '.manage_scene' do
    let(:builder) do
      Ephesus::Core::Scenes::Builder.new(scene_class)
    end
    let(:scene_class) { Spec::CustomScene }
    let(:error_message) do
      "unable to manage scene for abstract class #{described_class.name}"
    end

    example_class 'Spec::CustomScene', Ephesus::Core::Scene

    it 'should raise an exception' do
      expect { described_class.manage_scene(builder) }
        .to raise_error described_class::AbstractClassError, error_message
    end
  end
end
