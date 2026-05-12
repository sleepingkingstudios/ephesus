# frozen_string_literal: true

require 'ephesus/core/message'
require 'ephesus/core/rspec/deferred/messages_examples'
require 'ephesus/core/rspec/deferred/scenes_examples'
require 'ephesus/core/scene'

RSpec.describe Ephesus::Core::Scene do
  include Ephesus::Core::RSpec::Deferred::MessagesExamples
  include Ephesus::Core::RSpec::Deferred::ScenesExamples

  subject(:scene) { described_class.new(**constructor_options) }

  deferred_context 'when the scene has initial state' do |**initial_state|
    let(:state)               { initial_state }
    let(:constructor_options) { { state: } }
  end

  deferred_context 'with a scene subclass' do
    let(:described_class) { Spec::CustomScene }

    example_class 'Spec::CustomScene', Ephesus::Core::Scene # rubocop:disable RSpec/DescribedClass
  end

  let(:constructor_options) { {} }
  let(:default_event_handlers) do
    [
      Ephesus::Core::Commands::ConnectActor,
      Ephesus::Core::Commands::DisconnectActor
    ]
      .to_h { |command_class| [command_class.type, command_class] }
  end

  define_method :tools do
    SleepingKingStudios::Tools::Toolbelt.instance
  end

  example_class 'Spec::Publisher' do |klass|
    klass.include Ephesus::Core::Messaging::Publisher
  end

  example_class 'Spec::Subscriber' do |klass|
    klass.include Ephesus::Core::Messaging::Subscriber

    klass.define_method(:receive_message) { |_| nil }
  end

  describe '::UnhandledEventError' do
    include_examples 'should define constant',
      :UnhandledEventError,
      -> { be_a(Class).and be < StandardError }
  end

  describe '::UnhandledSideEffectError' do
    include_examples 'should define constant',
      :UnhandledSideEffectError,
      -> { be_a(Class).and be < StandardError }
  end

  include_deferred 'should implement the event handling interface'

  include_deferred 'should implement the event processing interface'

  include_deferred 'should publish messages'

  include_deferred 'should handle event',
    Ephesus::Core::Commands::ConnectActor

  include_deferred 'should handle event',
    Ephesus::Core::Commands::DisconnectActor

  wrap_deferred 'with a scene subclass' do
    include_deferred 'should implement the event handling methods'

    include_deferred 'should implement the event processing methods'
  end

  describe '.abstract?' do
    it { expect(described_class).to respond_to(:abstract?).with(0).arguments }

    it { expect(described_class.abstract?).to be true }

    wrap_deferred 'with a scene subclass' do
      it { expect(described_class.abstract?).to be false }
    end
  end

  describe '.handle_event' do
    let(:command_class) { Spec::CustomCommand }
    let(:options)       { {} }
    let(:error_message) do
      "unable to add event handler for abstract class #{described_class.name}"
    end

    example_class 'Spec::CustomCommand', Ephesus::Core::Command

    it 'should raise an exception' do
      expect { described_class.handle_event(command_class) }
        .to raise_error described_class::AbstractClassError, error_message
    end
  end

  describe '.type' do
    let(:expected) { 'ephesus.core' }

    include_examples 'should define class reader', :type, -> { expected }

    wrap_deferred 'with a scene subclass' do
      it { expect(described_class.type).to be == 'spec.custom' }

      context 'when the class defines a ::TYPE' do
        let(:expected) { 'spec.type_from_constant' }

        before(:example) { described_class.const_set(:TYPE, expected) }

        it { expect(described_class.type).to be == expected }
      end
    end
  end

  describe '.new' do
    it 'should define the constructor' do
      expect(described_class)
        .to be_constructible
        .with(0).arguments
        .and_keywords(:state)
    end
  end

  describe '#as_json' do
    let(:expected) { { 'id' => scene.id, 'type' => scene.type } }

    include_examples 'should define reader', :as_json, -> { expected }
  end

  describe '#handle_side_effect' do
    it 'should define the private method' do
      expect(scene)
        .to respond_to(:handle_side_effect, true)
        .with(1).argument
        .and_unlimited_arguments
    end

    describe 'with an unhandled side effect' do
      let(:side_effect) { :do_something }
      let(:details) do
        { this_is: 'something', therefore: 'we must do it' }
      end
      let(:error_message) do
        "no handler found for side effect #{side_effect.inspect} " \
          "(#{details.inspect})"
      end

      it 'should raise an exception' do
        expect { scene.send(:handle_side_effect, side_effect, details) }.to(
          raise_error(described_class::UnhandledSideEffectError, error_message)
        )
      end
    end

    describe 'with a :notify effect' do
      let(:side_effect)    { :notify }
      let(:original_actor) { Spec::Actor.new }
      let(:message) do
        Ephesus::Core::Messages::Notification.new(original_actor:)
      end
      let(:context) do
        { scene_type: scene.type }
      end

      example_class 'Spec::Actor', Ephesus::Core::Actor do |klass|
        klass.define_method(:notifications) { @notifications ||= [] }

        klass.define_method(:handle_notification) do |notification|
          notifications << notification
        end
      end

      it 'should not push the notification to the original actor' do
        scene.send(:handle_side_effect, side_effect, message)

        expect(original_actor.notifications).to be == []
      end

      describe 'with a message with current_actor: value' do
        let(:current_actor) { Spec::Actor.new }
        let(:message)       { super().with(current_actor:) }
        let(:expected)      { message.with(context:) }

        it 'should not push the notification to the original actor' do
          scene.send(:handle_side_effect, side_effect, message)

          expect(original_actor.notifications).to be == []
        end

        it 'should push the notification to the current actor' do
          scene.send(:handle_side_effect, side_effect, message)

          expect(current_actor.notifications).to be == [expected]
        end
      end

      context 'when the scene has one actor' do
        let(:actor)    { Spec::Actor.new }
        let(:expected) { message.with(context:, current_actor: actor) }
        let(:state)    { { 'actors' => { actor.id => actor } } }
        let(:constructor_options) do
          super().merge(state:)
        end

        it 'should not push the notification to the original actor' do
          scene.send(:handle_side_effect, side_effect, message)

          expect(original_actor.notifications).to be == []
        end

        it 'should push the notification to the actor' do
          scene.send(:handle_side_effect, side_effect, message)

          expect(actor.notifications).to be == [expected]
        end

        describe 'with a message with current_actor: value' do
          let(:current_actor) { Spec::Actor.new }
          let(:message)       { super().with(current_actor:) }
          let(:expected)      { message.with(context:) }

          it 'should push the notification to the current actor' do
            scene.send(:handle_side_effect, side_effect, message)

            expect(current_actor.notifications).to be == [expected]
          end

          it 'should not push the notification to the actor' do
            scene.send(:handle_side_effect, side_effect, message)

            expect(actor.notifications).to be == []
          end
        end
      end

      context 'when the scene has many actors' do
        let(:actors) { Array.new(3) { Spec::Actor.new } }
        let(:state) do
          { 'actors' => actors.to_h { |actor| [actor.id, actor] } }
        end
        let(:constructor_options) do
          super().merge(state:)
        end

        it 'should not push the notification to the original actor' do
          scene.send(:handle_side_effect, side_effect, message)

          expect(original_actor.notifications).to be == []
        end

        it 'should push the notification to each actor', :aggregate_failures do
          scene.send(:handle_side_effect, side_effect, message)

          actors.each do |actor|
            expect(actor.notifications)
              .to be == [message.with(context:, current_actor: actor)]
          end
        end

        describe 'with a message with current_actor: value' do
          let(:current_actor) { Spec::Actor.new }
          let(:message)       { super().with(current_actor:) }
          let(:expected)      { message.with(context:) }

          it 'should push the notification to the current actor' do
            scene.send(:handle_side_effect, side_effect, message)

            expect(current_actor.notifications).to be == [expected]
          end

          it 'should not push the notification to the actors',
            :aggregate_failures \
          do
            scene.send(:handle_side_effect, side_effect, message)

            actors.each do |actor|
              expect(actor.notifications).to be == []
            end
          end
        end
      end
    end

    describe 'with a :push_event effect' do
      let(:side_effect) { :push_event }
      let(:event) do
        Spec::CustomEvent.new(message: 'Greetings, programs!')
      end

      example_constant 'Spec::CustomEvent' do
        Ephesus::Core::Message.define(:message)
      end

      it 'should push the event to the #event_stack', :aggregate_failures do
        expect { scene.send(:handle_side_effect, side_effect, event) }.to(
          change { scene.send(:event_stack).count }.by(1)
        )

        expect(scene.send(:event_stack).last).to be == event
      end

      context 'when the scene has many stacked events' do
        before(:example) do
          3.times { scene.send(:event_stack).push(Ephesus::Core::Message.new) }
        end

        it 'should push the event to the #event_stack', :aggregate_failures do
          expect { scene.send(:handle_side_effect, side_effect, event) }.to(
            change { scene.send(:event_stack).count }.by(1)
          )

          expect(scene.send(:event_stack).last).to be == event
        end
      end
    end

    describe 'with a :subscribe effect' do
      let(:subscriber)  { instance_double(Spec::Subscriber, subscribe: nil) }
      let(:side_effect) { :subscribe }
      let(:options)     { { subscriber: } }
      let(:expected)    { options.except(:subscriber) }

      it 'should add the subscription' do
        scene.send(:handle_side_effect, side_effect, options)

        expect(subscriber).to have_received(:subscribe).with(scene, **expected)
      end

      describe 'with options' do
        let(:options) do
          super().merge(
            channel:     :notifications,
            method_name: :handle_notification
          )
        end

        it 'should add the subscription' do
          scene.send(:handle_side_effect, side_effect, options)

          expect(subscriber)
            .to have_received(:subscribe)
            .with(scene, **expected)
        end
      end
    end

    describe 'with an :unsubscribe effect' do
      let(:subscriber)  { instance_double(Spec::Subscriber, unsubscribe: nil) }
      let(:side_effect) { :unsubscribe }
      let(:options)     { { subscriber: } }
      let(:expected)    { options.except(:subscriber) }

      it 'should remove the subscription' do
        scene.send(:handle_side_effect, side_effect, options)

        expect(subscriber)
          .to have_received(:unsubscribe)
          .with(scene, **expected)
      end

      describe 'with options' do
        let(:options) do
          super().merge(channel: :notifications)
        end

        it 'should add the subscription' do
          scene.send(:handle_side_effect, side_effect, options)

          expect(subscriber)
            .to have_received(:unsubscribe)
            .with(scene, **expected)
        end
      end
    end

    describe 'with an :update_connection effect' do
      let(:side_effect) { :update_connection }
      let(:actor)       { Spec::Actor.new }
      let(:data)        { { name: 'Ed Dillinger', role: 'admin' } }
      let(:state)       { { 'actors' => { actor.id => actor } } }
      let(:constructor_options) do
        super().merge(state:)
      end

      example_class 'Spec::Actor', Ephesus::Core::Actor do |klass|
        klass.define_method(:connection_updates) { @connection_updates ||= [] }

        klass.define_method(:handle_connection_update) do |message|
          connection_updates << message
        end
      end

      describe 'with a non-matching actor ID' do
        let(:actor_id) { SecureRandom.uuid }

        it 'should not push the update to the actor' do
          scene.send(:handle_side_effect, side_effect, actor_id, data)

          expect(actor.connection_updates).to be == []
        end
      end

      describe 'with a matching actor ID' do
        let(:actor_id) { actor.id }
        let(:expected) do
          [Ephesus::Core::Connection::UpdateConnectionMessage.new(data:)]
        end

        it 'should push the update to the actor' do
          scene.send(:handle_side_effect, side_effect, actor_id, data)

          expect(actor.connection_updates).to be == expected
        end
      end

      context 'when the scene has many actors' do
        let(:actor_id) { actor.id }
        let(:actors) do
          [actor, *Array.new(3) { Spec::Actor.new }]
        end
        let(:state) do
          { 'actors' => actors.to_h { |actor| [actor.id, actor] } }
        end
        let(:expected) do
          [Ephesus::Core::Connection::UpdateConnectionMessage.new(data:)]
        end

        it 'should push the update to the actor' do
          scene.send(:handle_side_effect, side_effect, actor_id, data)

          expect(actor.connection_updates).to be == expected
        end

        it 'should not push the update to the other actors',
          :aggregate_failures \
        do
          scene.send(:handle_side_effect, side_effect, actor_id, data)

          actors.reject { |item| item == actor }.each do |actor|
            expect(actor.connection_updates).to be == []
          end
        end
      end
    end
  end

  describe '#id' do
    let(:expected_format) { /\A\h{8}-\h{4}-\h{4}-\h{4}-\h{12}\z/ }

    include_examples 'should define reader',
      :id,
      -> { be_a(String).and match(expected_format) }
  end

  describe '#inspect' do
    let(:expected) do
      "#<#{scene.class.name} id=#{scene.id.inspect} type=#{scene.type.inspect}>"
    end

    it { expect(scene.inspect).to be == expected }

    wrap_deferred 'with a scene subclass' do
      let(:expected) { "#{super()[...-1]} custom=true>" }

      before(:example) do
        Spec::CustomScene.define_method(:properties_to_inspect) do
          super().merge(custom: true)
        end
      end

      it { expect(scene.inspect).to be == expected }
    end
  end

  describe '#state' do
    let(:expected) { { 'actors' => {} } }

    include_examples 'should define reader',
      :state,
      -> { be_a(Ephesus::Core::State) }

    it { expect(scene.state.to_h).to be == expected }

    context 'when initialized with state: a Hash with String keys' do
      let(:state) { { 'secret' => '12345' } }
      let(:constructor_options) do
        super().merge(state:)
      end
      let(:expected) { super().merge(state) }

      it { expect(scene.state.to_h).to be == expected }
    end

    context 'when initialized with state: a Hash with Symbol keys' do
      let(:state) { { secret: '12345' } }
      let(:constructor_options) do
        super().merge(state:)
      end
      let(:expected) { super().merge(tools.hsh.convert_keys_to_strings(state)) }

      it { expect(scene.state.to_h).to be == expected }
    end

    wrap_deferred 'with a scene subclass' do
      it { expect(scene.state.to_h).to be == expected }

      context 'when the scene defines #build_state' do
        let(:expected) { super().merge('checksum' => 0xdeadbeef) }

        before(:example) do
          Spec::CustomScene.define_method(:build_state) do |state|
            super(state.merge('checksum' => 0xdeadbeef))
          end
        end

        it { expect(scene.state.to_h).to be == expected }
      end

      context 'when the scene defines #default_state' do
        let(:expected) { super().merge('checksum' => 0xdeadbeef) }

        before(:example) do
          Spec::CustomScene.define_method(:default_state) do
            super().merge('checksum' => 0xdeadbeef)
          end
        end

        it { expect(scene.state.to_h).to be == expected }
      end

      context 'when the scene defines a custom State' do
        before(:example) do
          Spec::CustomScene.const_set(:State, Class.new(Ephesus::Core::State))
        end

        it { expect(scene.state).to be_a described_class::State }
      end
    end
  end

  describe '#type' do
    let(:expected) { 'ephesus.core' }

    include_examples 'should define reader', :type, -> { expected }

    wrap_deferred 'with a scene subclass' do
      it { expect(scene.type).to be == 'spec.custom' }

      context 'when the class defines a ::TYPE' do
        let(:expected) { 'spec.type_from_constant' }

        before(:example) { described_class.const_set(:TYPE, expected) }

        it { expect(scene.type).to be == expected }
      end
    end
  end
end
