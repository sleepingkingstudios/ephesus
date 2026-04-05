# frozen_string_literal: true

require 'ephesus/core/engines/scene_management'
require 'ephesus/core/rspec/deferred/engines_examples'
require 'ephesus/core/rspec/deferred/messages_examples'

RSpec.describe Ephesus::Core::Engines::SceneManagement do
  include Ephesus::Core::RSpec::Deferred::EnginesExamples
  include Ephesus::Core::RSpec::Deferred::MessagesExamples

  subject(:engine) { described_class.new }

  let(:described_class) { Spec::CustomEngine }

  define_method :tools do
    SleepingKingStudios::Tools::Toolbelt.instance
  end

  example_class 'Spec::CustomEngine' do |klass|
    klass.include Ephesus::Core::Engines::SceneManagement # rubocop:disable RSpec/DescribedClass
  end

  example_class 'Spec::Publisher' do |klass|
    klass.include Ephesus::Core::Messaging::Publisher
  end

  describe '::SceneNotFoundError' do
    include_examples 'should define constant',
      :SceneNotFoundError,
      -> { be_a(Class).and(be < StandardError) }
  end

  include_deferred 'should subscribe to messages'

  include_deferred 'should implement the scene management interface'

  include_deferred 'should implement the scene management methods'

  describe '.abstract?' do
    include_examples 'should define class reader', :abstract?, false
  end

  describe '.manage_scene' do
    context 'with an abstract class' do
      let(:builder) do
        Ephesus::Core::Scenes::Builder.new(scene_class)
      end
      let(:scene_class) { Spec::CustomScene }
      let(:error_message) do
        "unable to manage scene for abstract class #{described_class.name}"
      end

      example_class 'Spec::CustomScene', Ephesus::Core::Scene

      before(:example) do
        described_class.define_singleton_method(:abstract?) { true }
      end

      it 'should raise an exception' do
        expect { described_class.manage_scene(builder) }
          .to raise_error described_class::AbstractClassError, error_message
      end
    end
  end
end
