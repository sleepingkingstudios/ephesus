# frozen_string_literal: true

require 'ephesus/core/messages/error_notification'

RSpec.describe Ephesus::Core::Messages::ErrorNotification do
  subject(:notification) { described_class.new(**options) }

  let(:original_actor) { Ephesus::Core::Actor.new }
  let(:message)        { 'Something went wrong.' }
  let(:options)        { { message:, original_actor: } }

  describe '.new' do
    let(:expected_keywords) do
      %i[
        current_actor
        context
        details
        error_id
        message
        original_actor
      ]
    end

    it 'should define the constructor' do
      expect(described_class)
        .to be_constructible
        .with(0).arguments
        .and_keywords(*expected_keywords)
    end
  end

  describe '.members' do
    let(:expected) do
      %i[
        current_actor
        original_actor
        context
        error_id
        message
        details
      ]
    end

    it { expect(described_class.members).to be == expected }
  end

  describe '#as_json' do
    let(:expected) do
      {
        'message' => message,
        'type'    => notification.type
      }
    end

    it { expect(notification).to respond_to(:as_json).with(0).arguments }

    it { expect(notification.as_json).to be == expected }

    context 'when the notification has details' do
      let(:details) { { password: 'password', secret: 12_345 } }
      let(:options) { super().merge(details:) }
      let(:expected) do
        super().merge('password' => 'password', 'secret' => 12_345)
      end

      it { expect(notification.as_json).to be == expected }
    end
  end

  describe '#context' do
    include_examples 'should define reader', :context, {}

    context 'when initialized with scene_type: value' do
      let(:context) { { scene_type: 'spec.custom_type' } }
      let(:options) { super().merge(context:) }

      it { expect(notification.context).to be == context }
    end

    context 'with a scene type' do
      let(:context) { { scene_type: 'spec.custom_type' } }

      it { expect(notification.with(context:).context).to be context }
    end
  end

  describe '#current_actor' do
    include_examples 'should define reader', :current_actor, nil

    context 'when initialized with current_actor: value' do
      let(:current_actor) { Ephesus::Core::Actor.new }
      let(:options)       { super().merge(current_actor:) }

      it { expect(notification.current_actor).to be == current_actor }
    end

    context 'with a current actor' do
      let(:current_actor) { Ephesus::Core::Actor.new }

      it 'should set the value' do
        expect(notification.with(current_actor:).current_actor)
          .to be == current_actor
      end
    end
  end

  describe '#details' do
    include_examples 'should define reader', :details, {}

    context 'when initialized with details' do
      let(:details) { { password: 'password', secret: 12_345 } }
      let(:options) { super().merge(details:) }

      it { expect(notification.details).to be == details }
    end
  end

  describe '#error_id' do
    let(:expected_format) { /\A\h{8}-\h{4}-\h{4}-\h{4}-\h{12}\z/ }

    include_examples 'should define reader',
      :error_id,
      -> { be_a(String).and match(expected_format) }

    context 'when initialized with an error ID' do
      let(:error_id) { '12345' }
      let(:options)  { super().merge(error_id:) }

      it { expect(notification.error_id).to be == error_id }
    end
  end

  describe '#message' do
    include_examples 'should define reader', :message, -> { message }
  end

  describe '#original_actor' do
    include_examples 'should define reader',
      :original_actor,
      -> { original_actor }
  end
end
