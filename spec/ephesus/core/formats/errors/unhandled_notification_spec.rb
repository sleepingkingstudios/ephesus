# frozen_string_literal: true

require 'ephesus/core/formats/errors/unhandled_notification'
require 'ephesus/core/messages/notification'

RSpec.describe Ephesus::Core::Formats::Errors::UnhandledNotification do
  subject(:error) { described_class.new(notification:) }

  let(:actor)        { Ephesus::Core::Actor.new }
  let(:notification) { Spec::CustomNotification.new(original_actor: actor) }

  example_constant 'Spec::CustomNotification' do
    Ephesus::Core::Messages::Notification.define
  end

  describe '::TYPE' do
    let(:expected) { 'ephesus.core.formats.errors.unhandled_notification' }

    it 'should define the constant' do
      expect(described_class).to define_constant(:TYPE).with_value(expected)
    end
  end

  describe '.new' do
    it 'should define the constructor' do
      expect(described_class)
        .to be_constructible
        .with(0).arguments
        .and_keywords(:notification)
    end
  end

  describe '#as_json' do
    let(:expected) do
      {
        'data'    => { 'notification' => notification.as_json },
        'message' => error.message,
        'type'    => error.type
      }
    end

    include_examples 'should have reader', :as_json, -> { be == expected }
  end

  describe '#message' do
    let(:expected) do
      "Unhandled notification #{notification.type.inspect}"
    end

    include_examples 'should define reader', :message, -> { expected }

    context 'when the notification has properties' do
      let(:notification) do
        Spec::NotificationWithProperties.new(
          original_actor: actor,
          password:       'password',
          secret:         12_345
        )
      end
      let(:expected) do
        %(#{super()} with properties password: "password", secret: 12345)
      end

      example_constant 'Spec::NotificationWithProperties' do
        Ephesus::Core::Messages::Notification.define(:password, :secret)
      end

      it { expect(error.message).to be == expected }
    end
  end

  describe '#notification' do
    include_examples 'should define reader', :notification, -> { notification }
  end

  describe '#type' do
    include_examples 'should define reader', :type, described_class::TYPE
  end
end
