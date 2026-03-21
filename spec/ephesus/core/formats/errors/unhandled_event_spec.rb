# frozen_string_literal: true

require 'ephesus/core/formats/errors/unhandled_event'
require 'ephesus/core/message'
require 'ephesus/core/scene'

RSpec.describe Ephesus::Core::Formats::Errors::UnhandledEvent do
  subject(:error) { described_class.new(event:, scene:) }

  let(:event) { Spec::CustomEvent.new }
  let(:scene) { Spec::CustomScene.new }

  example_constant 'Spec::CustomEvent' do
    Ephesus::Core::Message.define
  end

  example_class 'Spec::CustomScene', Ephesus::Core::Scene

  describe '::TYPE' do
    let(:expected) { 'ephesus.core.formats.errors.unhandled_event' }

    it 'should define the constant' do
      expect(described_class).to define_constant(:TYPE).with_value(expected)
    end
  end

  describe '.new' do
    it 'should define the constructor' do
      expect(described_class)
        .to be_constructible
        .with(0).arguments
        .and_keywords(:event, :scene)
    end
  end

  describe '#as_json' do
    let(:expected) do
      {
        'data'    => {
          'event' => event.as_json,
          'scene' => scene.as_json
        },
        'message' => error.message,
        'type'    => error.type
      }
    end

    include_examples 'should have reader', :as_json, -> { be == expected }
  end

  describe '#event' do
    include_examples 'should define reader', :event, -> { event }
  end

  describe '#message' do
    let(:expected) do
      "Unhandled event #{event.type.inspect} for scene #{scene.type.inspect}"
    end

    include_examples 'should define reader', :message, -> { expected }
  end

  describe '#scene' do
    include_examples 'should define reader', :scene, -> { scene }
  end

  describe '#type' do
    include_examples 'should define reader', :type, described_class::TYPE
  end
end
