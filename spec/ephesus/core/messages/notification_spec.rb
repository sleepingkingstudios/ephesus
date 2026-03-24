# frozen_string_literal: true

require 'ephesus/core/messages/notification'

RSpec.describe Ephesus::Core::Messages::Notification do
  subject(:message) { described_class.new(**options) }

  let(:original_actor) { Ephesus::Core::Actor.new }
  let(:options)        { { original_actor: } }

  describe '.new' do
    it 'should define the constructor' do
      expect(described_class)
        .to be_constructible
        .with(0).arguments
        .and_keywords(:current_actor, :original_actor, :context)
    end
  end

  describe '.members' do
    let(:expected) { %i[current_actor original_actor context] }

    it { expect(described_class.members).to be == expected }
  end

  describe '#as_json' do
    let(:expected) do
      {
        'context'        => {},
        'current_actor'  => nil,
        'original_actor' => original_actor.as_json,
        'type'           => message.type
      }
    end

    it { expect(message).to respond_to(:as_json).with(0).arguments }

    it { expect(message.as_json).to be == expected }

    context 'when initialized with scene_type: value' do
      let(:context) { { scene_type: 'spec.custom_type' } }
      let(:options) { super().merge(context:) }
      let(:expected) do
        super().merge('context' => { 'scene_type' => context[:scene_type] })
      end

      it { expect(message.as_json).to be == expected }
    end

    context 'when initialized with current_actor: value' do
      let(:current_actor) { Ephesus::Core::Actor.new }
      let(:options)       { super().merge(current_actor:) }
      let(:expected) do
        super().merge('current_actor' => current_actor.as_json)
      end

      it { expect(message.as_json).to be == expected }
    end
  end

  describe '#context' do
    include_examples 'should define reader', :context, {}

    context 'when initialized with scene_type: value' do
      let(:context) { { scene_type: 'spec.custom_type' } }
      let(:options) { super().merge(context:) }

      it { expect(message.context).to be == context }
    end

    context 'with a scene type' do
      let(:context) { { scene_type: 'spec.custom_type' } }

      it { expect(message.with(context:).context).to be context }
    end
  end

  describe '#current_actor' do
    include_examples 'should define reader', :current_actor, nil

    context 'when initialized with current_actor: value' do
      let(:current_actor) { Ephesus::Core::Actor.new }
      let(:options)       { super().merge(current_actor:) }

      it { expect(message.current_actor).to be == current_actor }
    end

    context 'with a current actor' do
      let(:current_actor) { Ephesus::Core::Actor.new }

      it 'should set the value' do
        expect(message.with(current_actor:).current_actor)
          .to be == current_actor
      end
    end
  end

  describe '#original_actor' do
    include_examples 'should define reader',
      :original_actor,
      -> { original_actor }
  end
end
