# frozen_string_literal: true

require 'ephesus/core/engines/errors/actor_not_assigned_scene'

RSpec.describe Ephesus::Core::Engines::Errors::ActorNotAssignedScene do
  subject(:error) { described_class.new(actor:, **options) }

  let(:actor)   { Ephesus::Core::Actor.new }
  let(:options) { {} }

  describe '::TYPE' do
    let(:expected) { 'ephesus.core.engines.errors.actor_not_assigned_scene' }

    it 'should define the constant' do
      expect(described_class).to define_constant(:TYPE).with_value(expected)
    end
  end

  describe '.new' do
    it 'should define the constructor' do
      expect(described_class)
        .to be_constructible
        .with(0).arguments
        .and_keywords(:actor, :message)
    end
  end

  describe '#actor' do
    include_examples 'should define reader', :actor, -> { actor }
  end

  describe '#as_json' do
    let(:expected) do
      {
        'data'    => { 'actor' => actor.as_json },
        'message' => error.message,
        'type'    => error.type
      }
    end

    include_examples 'should have reader', :as_json, -> { be == expected }
  end

  describe '#message' do
    let(:expected) { "actor #{actor.inspect} is not assigned to a scene" }

    include_examples 'should define reader', :message, -> { be == expected }

    context 'when initialized with message: value' do
      let(:message)  { 'Something went wrong' }
      let(:options)  { super().merge(message:) }
      let(:expected) { "#{message} - #{super()}" }

      it { expect(error.message).to be == expected }
    end
  end

  describe '#type' do
    include_examples 'should define reader', :type, described_class::TYPE
  end
end
