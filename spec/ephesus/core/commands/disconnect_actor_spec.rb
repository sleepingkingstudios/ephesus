# frozen_string_literal: true

require 'ephesus/core/actor'
require 'ephesus/core/commands/disconnect_actor'
require 'ephesus/core/state'

RSpec.describe Ephesus::Core::Commands::DisconnectActor do
  subject(:command) { described_class.new }

  describe '::Event' do
    include_examples 'should define constant', :Event

    it { expect(described_class::Event).to be_a(Class).and(be < Data) }

    it { expect(described_class::Event.members).to be == %i[actor] }
  end

  describe '#call' do
    let(:actor) { Ephesus::Core::Actor.new }
    let(:event) { described_class::Event.new(actor:) }
    let(:state) { Ephesus::Core::State.new({ 'actors' => {} }) }
    let(:expected_state) do
      state.delete('actors', actor.id)
    end
    let(:expected_side_effects) do
      options = {
        channel:    :notifications,
        subscriber: actor
      }

      [[:unsubscribe, options]]
    end

    it 'should define the method' do
      expect(command)
        .to be_callable
        .with(0).arguments
        .and_keywords(:event, :state)
    end

    it { expect(command.call(event:, state:)).to be_a_passing_result }

    it 'should update the state' do
      returned_state, * = command.call(event:, state:).value

      expect(returned_state).to be == expected_state
    end

    it 'should return the side effects' do
      _, *returned_side_effects = command.call(event:, state:).value

      expect(returned_side_effects).to be == expected_side_effects
    end
  end
end
