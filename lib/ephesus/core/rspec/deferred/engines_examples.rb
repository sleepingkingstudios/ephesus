# frozen_string_literal: true

require 'rspec/sleeping_king_studios/deferred'

require 'ephesus/core/rspec/deferred'

module Ephesus::Core::RSpec::Deferred
  # Deferred examples for testing engines.
  module EnginesExamples
    include RSpec::SleepingKingStudios::Deferred::Provider

    deferred_context 'when the engine manages scenes' do
      example_class 'Spec::Fantasy::Battle',       Ephesus::Core::Scene
      example_class 'Spec::Fantasy::Conversation', Ephesus::Core::Scene
      example_class 'Spec::Fantasy::Inventory',    Ephesus::Core::Scene

      before(:example) do
        Spec::CustomEngine.manage_scene(
          Spec::Fantasy::Battle,
          scene_type: 'spec.scenes.battle'
        )

        Spec::CustomEngine.manage_scene(Spec::Fantasy::Conversation)
        Spec::CustomEngine.manage_scene(Spec::Fantasy::Inventory)
      end
    end

    deferred_examples 'should manage scene' \
    do |scene_class = nil, type: nil|
      scene_type = type || scene_class
      scene_type = scene_type.type if scene_type.respond_to?(:type)
      message    = "should define the #{scene_type || 'scene'} pool"

      describe(message) do
        let(:expected_scene) do
          next super() if defined?(super())

          if scene_class.is_a?(String)
            scene_class = Object.const_get(scene_class)
          end

          scene_class
        end
        let(:expected_type) do
          return super() if defined?(super())

          scene_type = type || scene_class
          scene_type = Object.const_get(scene_type) if scene_type.include?(':')
          scene_type = scene_type.type if scene_type.respond_to?(:type)

          scene_type
        end

        specify do
          pool_class = described_class.managed_scenes.fetch(expected_type)

          expect(pool_class.new.builder.scene_class).to be == expected_scene
        end
      end
    end

    deferred_examples 'should implement the connection management interface' \
    do
      describe '#actors' do
        include_examples 'should define private reader', :actors
      end

      describe '#add_actor_to_scene' do
        it 'should define the method' do
          expect(subject)
            .to respond_to(:add_actor_to_scene)
            .with(0).arguments
            .and_keywords(:actor, :scene)
        end
      end

      describe '#add_connection' do
        it { expect(subject).to respond_to(:add_connection).with(1).argument }
      end

      describe '#build_actor' do
        it 'should define the private method' do
          expect(subject).to respond_to(:build_actor, true).with(1).argument
        end
      end

      describe '#connections' do
        include_examples 'should define private reader', :connections
      end

      describe '#default_scene' do
        it 'should define the private method' do
          expect(subject).to respond_to(:default_scene, true).with(0).arguments
        end
      end

      describe '#enqueue_event' do
        it 'should define the private method' do
          expect(subject)
            .to respond_to(:enqueue_event, true)
            .with(0).arguments
            .and_keywords(:event, :scene)
        end
      end

      describe '#handle_event' do
        it { expect(subject).to respond_to(:handle_event).with(1).argument }
      end

      describe '#remove_actor_from_scene' do
        it 'should define the method' do
          expect(subject)
            .to respond_to(:remove_actor_from_scene)
            .with(0).arguments
            .and_keywords(:actor)
        end
      end

      describe '#remove_connection' do
        it 'should define the method' do
          expect(subject).to respond_to(:remove_connection).with(1).argument
        end
      end
    end

    deferred_examples 'should implement the connection management methods' \
    do |**example_options|
      describe '#actors' do
        it { expect(subject.send(:actors)).to be == {} }
      end

      describe '#add_actor_to_scene' do
        let(:actor) { Ephesus::Core::Actor.new }
        let(:scene) { Ephesus::Core::Scene.new }
        let(:connect_event) do
          Ephesus::Core::Commands::ConnectActor::Event.new(actor)
        end

        before(:example) do
          allow(subject).to receive(:enqueue_event)
        end

        it { expect(subject.add_actor_to_scene(actor:, scene:)).to be nil }

        it 'should set the current scene for the actor' do
          expect { subject.add_actor_to_scene(actor:, scene:) }
            .to change(actor, :current_scene)
            .to be scene
        end

        it 'should enqueue a ConnectActor event' do
          subject.add_actor_to_scene(actor:, scene:)

          expect(subject)
            .to have_received(:enqueue_event)
            .with(event: connect_event, scene:)
        end

        context 'when the actor has a current scene' do
          let(:previous_scene) { Ephesus::Core::Scene.new }
          let(:disconnect_event) do
            Ephesus::Core::Commands::DisconnectActor::Event.new(actor)
          end

          before(:example) { actor.current_scene = previous_scene }

          it { expect(subject.add_actor_to_scene(actor:, scene:)).to be nil }

          it 'should set the current scene for the actor' do
            expect { subject.add_actor_to_scene(actor:, scene:) }
              .to change(actor, :current_scene)
              .to be scene
          end

          it 'should enqueue a ConnectActor event' do
            subject.add_actor_to_scene(actor:, scene:)

            expect(subject)
              .to have_received(:enqueue_event)
              .with(event: connect_event, scene:)
          end

          it 'should enqueue a DisconnectActor event for the previous scene' do
            subject.add_actor_to_scene(actor:, scene:)

            expect(subject)
              .to have_received(:enqueue_event)
              .with(event: disconnect_event, scene: previous_scene)
          end
        end
      end

      describe '#add_connection' do
        next if example_options.fetch(:except, []).include?(:add_connection)

        let(:connection) do
          Ephesus::Core::Connection.new(format: 'spec.format')
        end
        let(:expected_actor) do
          subject.send(:build_actor, connection)
        end
        let(:message) { Ephesus::Core::Message.new }

        before(:example) do
          allow(subject).to receive(:build_actor).and_return(expected_actor)
        end

        it 'should add the connection to #connections', :aggregate_failures do # rubocop:disable RSpec/ExampleLength
          expect { subject.send(:add_connection, connection) }.to(
            change { subject.send(:connections).keys }.to(
              include(connection.id)
            )
          )

          expect(subject.send(:connections)[connection.id]).to be connection
        end

        it 'should build the actor' do
          subject.send(:add_connection, connection)

          expect(subject).to have_received(:build_actor).with(connection)
        end

        it 'should set the connection actor' do
          expect { subject.send(:add_connection, connection) }
            .to change(connection, :actor)
            .to be expected_actor
        end

        it 'should subscribe to events from the connection' do
          allow(subject).to receive(:handle_event)

          subject.send(:add_connection, connection)

          connection.publish(message, channel: :events)

          expect(subject).to have_received(:handle_event).with(message)
        end

        context 'when the connection already has an actor' do
          let(:actor) { Ephesus::Core::Actor.new }
          let(:error_message) do
            "unable to add connection #{connection.inspect} - connection " \
              'already has an actor'
          end

          before(:example) { connection.actor = actor }

          it 'should raise an exception' do
            expect { subject.send(:add_connection, connection) }
              .to raise_error described_class::ConnectionError, error_message
          end
        end
      end

      describe '#connections' do
        it { expect(subject.send(:connections)).to be == {} }
      end

      describe '#remove_actor_from_scene' do
        let(:actor) { Ephesus::Core::Actor.new }

        before(:example) do
          allow(subject).to receive(:enqueue_event)
        end

        it { expect(subject.remove_actor_from_scene(actor:)).to be nil }

        it 'should not change the current scene for the actor' do
          expect { subject.remove_actor_from_scene(actor:) }
            .not_to change(actor, :current_scene)
        end

        context 'when the actor has a current scene' do
          let(:previous_scene) { Ephesus::Core::Scene.new }
          let(:disconnect_event) do
            Ephesus::Core::Commands::DisconnectActor::Event.new(actor)
          end

          before(:example) { actor.current_scene = previous_scene }

          it { expect(subject.remove_actor_from_scene(actor:)).to be nil }

          it 'should clear the current scene for the actor' do
            expect { subject.remove_actor_from_scene(actor:) }
              .to change(actor, :current_scene)
              .to be nil
          end

          it 'should enqueue a DisconnectActor event' do
            subject.remove_actor_from_scene(actor:)

            expect(subject)
              .to have_received(:enqueue_event)
              .with(event: disconnect_event, scene: previous_scene)
          end
        end
      end

      describe '#remove_connection' do
        let(:connection) do
          Ephesus::Core::Connection.new(format: 'spec.format')
        end
        let(:message) { Ephesus::Core::Message.new }

        before(:example) { subject.add_connection(connection) }

        it 'should remove the connection from #connections' do
          expect { subject.remove_connection(connection) }.to(
            change { subject.send(:connections) }.to(
              satisfy { |hsh| !hsh.key?(connection.id) }
            )
          )
        end

        it 'should unsubscribe from events from the connection' do
          allow(subject).to receive(:handle_event)

          subject.remove_connection(connection)

          connection.publish(message, channel: :events)

          expect(subject).not_to have_received(:handle_event)
        end

        context 'when the actor has a current scene' do
          let(:previous_scene) { Ephesus::Core::Scene.new }
          let(:disconnect_event) do
            Ephesus::Core::Commands::DisconnectActor::Event
              .new(connection.actor)
          end

          before(:example) do
            connection.actor.current_scene = previous_scene

            allow(subject).to receive(:enqueue_event)
          end

          it 'should clear the current scene for the actor' do
            expect { subject.remove_connection(connection) }
              .to change(connection.actor, :current_scene)
              .to be nil
          end

          it 'should enqueue a DisconnectActor event' do
            subject.remove_connection(connection)

            expect(subject)
              .to have_received(:enqueue_event)
              .with(event: disconnect_event, scene: previous_scene)
          end
        end
      end
    end

    deferred_examples 'should implement the event handling interface' do
      describe '#enqueue_event' do
        it 'should define the private method' do
          expect(subject)
            .to respond_to(:enqueue_event, true)
            .with(0).arguments
            .and_keywords(:event, :scene)
        end
      end

      describe '#handle_event' do
        it { expect(subject).to respond_to(:handle_event).with(1).argument }
      end
    end

    deferred_examples 'should implement the event handling methods' do
      describe '#enqueue_event' do
        let(:event) { Ephesus::Core::Message.new }
        let(:scene) do
          instance_double(Ephesus::Core::Scene, enqueue_event: nil)
        end

        it 'should delegate to the scene' do
          subject.send(:enqueue_event, event:, scene:)

          expect(scene).to have_received(:enqueue_event).with(event)
        end
      end

      describe '#handle_event' do
        let(:connection) do
          Ephesus::Core::Connection.new(format: 'spec.format')
        end
        let(:event) do
          Ephesus::Core::Messages::LazyConnectionMessage.new(connection:)
        end
        let(:messages) { [] }

        before(:example) do
          allow(connection).to receive(:handle_notification) do |message|
            messages << message
          end
        end

        context 'when the connection does not have an actor' do
          let(:expected_error) do
            Ephesus::Core::Engines::Errors::MissingActor.new
          end
          let(:expected_message) do
            be_a(Ephesus::Core::Messages::ErrorNotification)
              .and have_attributes(
                error:          expected_error,
                original_actor: nil
              )
          end

          it 'should publish an error notification to the connection' do
            subject.handle_event(event)

            expect(messages).to contain_exactly(expected_message)
          end
        end

        context 'when the actor is not assigned to a scene' do
          let(:actor) { Ephesus::Core::Actor.new }
          let(:expected_error) do
            Ephesus::Core::Engines::Errors::ActorNotAssignedScene.new(actor:)
          end
          let(:expected_message) do
            be_a(Ephesus::Core::Messages::ErrorNotification)
              .and have_attributes(
                error:          expected_error,
                original_actor: actor
              )
          end

          before(:example) { connection.actor = actor }

          it 'should publish an error notification to the connection' do
            subject.handle_event(event)

            expect(messages).to contain_exactly(expected_message)
          end
        end

        context 'when the connection cannot format the event' do
          let(:scene) { Ephesus::Core::Scene.new }
          let(:actor) { Ephesus::Core::Actor.new }
          let(:expected_error) do
            connection.format_input(event:, scene:).error
          end
          let(:expected_message) do
            be_a(Ephesus::Core::Messages::ErrorNotification)
              .and have_attributes(
                error:          expected_error,
                original_actor: actor
              )
          end

          before(:example) do
            connection.actor = actor

            actor.current_scene = scene
          end

          it 'should publish an error notification to the connection' do
            subject.handle_event(event)

            expect(messages).to contain_exactly(expected_message)
          end
        end

        context 'when the connection formats the event' do
          let(:scene)   { Spec::CustomScene.new }
          let(:actor)   { Ephesus::Core::Actor.new }
          let(:formats) { { 'spec.format' => Spec::CustomFormatter } }
          let(:connection) do
            Ephesus::Core::Connection.new(format: 'spec.format', formats:)
          end
          let(:formatted_message) do
            Ephesus::Core::Formats::InputMessage.new(format: 'spec.format')
          end
          let(:result) { Cuprum::Result.new(value: formatted_message) }

          example_class 'Spec::CustomFormatter' do |klass|
            format_result = result

            klass.define_method :initialize do |**options|
              @options = options
            end

            klass.attr_reader :options

            klass.define_method :format_input do |**|
              format_result
            end
          end

          example_class 'Spec::CustomScene', Ephesus::Core::Scene

          before(:example) do
            connection.actor = actor

            actor.current_scene = scene

            allow(subject).to receive(:enqueue_event)
          end

          it 'should enqueue the formatted event' do
            subject.handle_event(event)

            expect(subject)
              .to have_received(:enqueue_event)
              .with(event: formatted_message, scene:)
          end

          it 'should not publish an error notification' do
            subject.handle_event(event)

            expect(messages).to be == []
          end
        end
      end
    end

    deferred_examples 'should implement the scene management interface' do
      describe '.manage_scene' do
        it 'should define the class method' do
          expect(described_class)
            .to respond_to(:manage_scene)
            .with(1).argument
            .and_keywords(:scene_type)
            .and_any_keywords
        end
      end

      describe '.managed_scenes' do
        include_examples 'should define class reader', :managed_scenes
      end

      describe '#default_scene' do
        it 'should define the private method' do
          expect(subject).to respond_to(:default_scene, true).with(0).arguments
        end
      end

      describe '#get_scene' do
        it 'should define the method' do
          expect(subject)
            .to respond_to(:get_scene)
            .with(1).argument
            .and_any_keywords
        end
      end

      describe '#handle_scene_added' do
        it 'should define the method' do
          expect(subject).to respond_to(:handle_scene_added).with(1).argument
        end
      end

      describe '#scenes' do
        include_examples 'should define private reader', :scenes
      end

      describe '#scene_pools' do
        include_examples 'should define private reader', :scene_pools
      end
    end

    deferred_examples 'should implement the scene management methods' \
    do |**example_options|
      describe '.manage_scene' do
        deferred_examples 'should register the scene pool' do
          it { expect(manage_scene).to be == expected_type }

          context 'when the scene pool is registered' do
            before(:example) { manage_scene }

            include_deferred 'should manage scene', 'Spec::CustomScene'

            it { expect(registered_class).to be_a Class }

            it { expect(registered_class).to be < Ephesus::Core::Scenes::Pool }

            it 'should define the pool constructor' do
              expect(registered_class).to be_constructible.with(0).arguments
            end

            it { expect(pool_instance.builder).to match expected_builder }

            it { expect(pool_instance.options).to match expected_options }

            it { expect(pool_instance.type).to match expected_type }
          end
        end

        let(:options) { {} }
        let(:error_message) do
          'value is not a Scenes::Builder instance, a Scenes::Pool class or ' \
            'a Scene class'
        end
        let(:registered_class) { described_class.managed_scenes[expected_type] }
        let(:pool_instance)    { registered_class.new }

        describe 'with nil' do
          it 'should raise an exception' do
            expect { described_class.manage_scene(nil) }
              .to raise_error ArgumentError, error_message
          end
        end

        describe 'with an Object' do
          it 'should raise an exception' do
            expect { described_class.manage_scene(Object.new.freeze) }
              .to raise_error ArgumentError, error_message
          end
        end

        describe 'with a Class' do
          it 'should raise an exception' do
            expect { described_class.manage_scene(Class.new) }
              .to raise_error ArgumentError, error_message
          end
        end

        describe 'with a Builder instance' do
          let(:builder) do
            Ephesus::Core::Scenes::Builder.new(scene_class)
          end
          let(:scene_class)      { Spec::CustomScene }
          let(:expected_type)    { builder.type }
          let(:expected_builder) { builder }
          let(:expected_scene)   { builder.scene_class }
          let(:expected_options) { {} }

          example_class 'Spec::CustomScene', Ephesus::Core::Scene

          define_method :manage_scene do
            described_class.manage_scene(builder, **options)
          end

          include_deferred 'should register the scene pool'

          describe 'with scene_type: a Scene' do
            let(:options)       { super().merge(scene_type: Spec::OtherScene) }
            let(:expected_type) { Spec::OtherScene.type }

            example_class 'Spec::OtherScene', Ephesus::Core::Scene

            include_deferred 'should register the scene pool'
          end

          describe 'with scene_type: a valid String' do
            let(:options)       { super().merge(scene_type: 'spec.other') }
            let(:expected_type) { 'spec.other' }

            include_deferred 'should register the scene pool'
          end

          describe 'with scene_type: a valid Symbol' do
            let(:options)       { super().merge(scene_type: :'spec.other') }
            let(:expected_type) { 'spec.other' }

            include_deferred 'should register the scene pool'
          end

          describe 'with options' do
            let(:options) do
              super().merge(custom_property: 'custom value')
            end
            let(:expected_options) { super().merge(options) }

            include_deferred 'should register the scene pool'
          end

          context 'when the scene class defines a Pool' do
            example_class 'Spec::CustomScene::Pool', Ephesus::Core::Scenes::Pool

            include_deferred 'should register the scene pool'

            context 'when the scene pool is registered' do
              before(:example) { manage_scene }

              it { expect(registered_class).to be < Spec::CustomScene::Pool }
            end
          end
        end

        describe 'with a Pool class' do
          let(:scene_class) { Spec::CustomScene }
          let(:builder)     { Ephesus::Core::Scenes::Builder.new(scene_class) }
          let(:pool_class)  { Spec::CustomPool }
          let(:error_message) do
            tools.assertions.error_message_for(:presence, as: 'scene_type')
          end

          example_class 'Spec::CustomScene', Ephesus::Core::Scene

          example_class 'Spec::CustomPool',
            Ephesus::Core::Scenes::Pool \
          do |klass|
            static_builder = builder

            klass.define_method(:initialize) do |**options|
              super(static_builder, **options)
            end
          end

          define_method :manage_scene do
            described_class.manage_scene(pool_class, **options)
          end

          it 'should raise an exception' do
            expect { described_class.manage_scene(pool_class, scene_type: nil) }
              .to raise_error ArgumentError, error_message
          end

          describe 'with scene_type: value' do # rubocop:disable RSpec/MultipleMemoizedHelpers
            let(:options)          { super().merge(scene_type: 'spec.custom') }
            let(:expected_type)    { 'spec.custom' }
            let(:expected_builder) { builder }
            let(:expected_scene)   { builder.scene_class }
            let(:expected_options) { {} }

            include_deferred 'should register the scene pool'

            describe 'with options' do # rubocop:disable RSpec/MultipleMemoizedHelpers
              let(:options) do
                super().merge(custom_property: 'custom value')
              end
              let(:expected_options) do
                super().merge(options.except(:scene_type))
              end

              include_deferred 'should register the scene pool'
            end
          end
        end

        describe 'with a Scene class' do
          let(:scene_class)      { Spec::CustomScene }
          let(:expected_type)    { scene_class.type }
          let(:expected_builder) { be_a(Ephesus::Core::Scenes::Builder) }
          let(:expected_scene)   { scene_class }
          let(:expected_options) { {} }

          example_class 'Spec::CustomScene', Ephesus::Core::Scene

          define_method :manage_scene do
            described_class.manage_scene(scene_class, **options)
          end

          include_deferred 'should register the scene pool'

          describe 'with scene_type: a Scene' do
            let(:options)       { super().merge(scene_type: Spec::OtherScene) }
            let(:expected_type) { Spec::OtherScene.type }

            example_class 'Spec::OtherScene', Ephesus::Core::Scene

            include_deferred 'should register the scene pool'
          end

          describe 'with scene_type: a valid String' do
            let(:options)       { super().merge(scene_type: 'spec.other') }
            let(:expected_type) { 'spec.other' }

            include_deferred 'should register the scene pool'
          end

          describe 'with scene_type: a valid Symbol' do
            let(:options)       { super().merge(scene_type: :'spec.other') }
            let(:expected_type) { 'spec.other' }

            include_deferred 'should register the scene pool'
          end

          describe 'with options' do
            let(:options) do
              super().merge(custom_property: 'custom value')
            end
            let(:expected_options) { super().merge(options) }

            include_deferred 'should register the scene pool'
          end

          context 'when the scene class defines a Builder' do
            let(:expected_builder) { be_a(Spec::CustomScene::Builder) }

            example_class 'Spec::CustomScene::Builder',
              Ephesus::Core::Scenes::Builder

            include_deferred 'should register the scene pool'

            context 'when the builder does not take a scene parameter' do
              before(:example) do
                configured_class = scene_class

                Spec::CustomScene::Builder.define_method(:initialize) do |**_|
                  super(configured_class)
                end
              end

              include_deferred 'should register the scene pool'
            end
          end

          context 'when the scene class defines a Pool' do
            example_class 'Spec::CustomScene::Pool', Ephesus::Core::Scenes::Pool

            include_deferred 'should register the scene pool'

            context 'when the scene pool is registered' do
              before(:example) { manage_scene }

              it { expect(registered_class).to be < Spec::CustomScene::Pool }
            end

            context 'when the pool does not take a builder parameter' do
              let(:expected_builder) do
                Ephesus::Core::Scenes::Builder.new(scene_class)
              end

              before(:example) do
                configured_builder = expected_builder

                Spec::CustomScene::Pool.define_method(:initialize) do |**_|
                  super(configured_builder)
                end
              end

              include_deferred 'should register the scene pool'
            end
          end
        end

        describe 'with scene_type: nil' do
          let(:builder) do
            Ephesus::Core::Scenes::Builder.new(Ephesus::Core::Scene)
          end
          let(:error_message) do
            tools.assertions.error_message_for(:presence, as: 'scene_type')
          end

          it 'should raise an exception' do
            expect { described_class.manage_scene(builder, scene_type: nil) }
              .to raise_error ArgumentError, error_message
          end
        end

        describe 'with scene_type: an Object' do
          let(:builder) do
            Ephesus::Core::Scenes::Builder.new(Ephesus::Core::Scene)
          end
          let(:scene_type) { Object.new.freeze }
          let(:error_message) do
            tools.assertions.error_message_for(:name, as: 'scene_type')
          end

          it 'should raise an exception' do
            expect { described_class.manage_scene(builder, scene_type:) }
              .to raise_error ArgumentError, error_message
          end
        end

        describe 'with scene_type: an empty String' do
          let(:builder) do
            Ephesus::Core::Scenes::Builder.new(Ephesus::Core::Scene)
          end
          let(:error_message) do
            tools.assertions.error_message_for(:presence, as: 'scene_type')
          end

          it 'should raise an exception' do
            expect { described_class.manage_scene(builder, scene_type: '') }
              .to raise_error ArgumentError, error_message
          end
        end

        describe 'with scene_type: an empty Symbol' do
          let(:builder) do
            Ephesus::Core::Scenes::Builder.new(Ephesus::Core::Scene)
          end
          let(:error_message) do
            tools.assertions.error_message_for(:presence, as: 'scene_type')
          end

          it 'should raise an exception' do
            expect { described_class.manage_scene(builder, scene_type: :'') }
              .to raise_error ArgumentError, error_message
          end
        end

        describe 'with scene_type: an invalid String' do
          let(:builder) do
            Ephesus::Core::Scenes::Builder.new(Ephesus::Core::Scene)
          end
          let(:scene_type) { 'InvalidFormat' }
          let(:error_message) do
            'scene_type must be a lowercase underscored string separated by ' \
              'periods'
          end

          it 'should raise an exception' do
            expect { described_class.manage_scene(builder, scene_type:) }
              .to raise_error ArgumentError, error_message
          end
        end

        describe 'with scene_type: an invalid Symbol' do
          let(:builder) do
            Ephesus::Core::Scenes::Builder.new(Ephesus::Core::Scene)
          end
          let(:scene_type) { :InvalidFormat }
          let(:error_message) do
            'scene_type must be a lowercase underscored string separated by ' \
              'periods'
          end

          it 'should raise an exception' do
            expect { described_class.manage_scene(builder, scene_type:) }
              .to raise_error ArgumentError, error_message
          end
        end
      end

      describe '.managed_scenes' do
        let(:expected) { {} }

        it { expect(described_class.managed_scenes).to be == expected }

        wrap_deferred 'when the engine manages scenes' do
          let(:expected_keys) do
            %w[
              spec.scenes.battle
              spec.fantasy.conversation
              spec.fantasy.inventory
            ]
          end

          it 'should define the expected scene pools' do
            expect(described_class.managed_scenes.keys)
              .to match_array(expected_keys)
          end

          include_deferred 'should manage scene',
            'Spec::Fantasy::Battle',
            type: 'spec.scenes.battle'

          include_deferred 'should manage scene', 'Spec::Fantasy::Conversation'

          include_deferred 'should manage scene', 'Spec::Fantasy::Inventory'
        end

        describe 'with a subclass of the engine' do
          let(:parent_class)    { Spec::CustomEngine }
          let(:described_class) { Spec::EngineSubclass }

          example_class 'Spec::EngineSubclass', 'Spec::CustomEngine'

          it { expect(described_class.managed_scenes).to be == expected }

          wrap_deferred 'when the engine manages scenes' do
            let(:expected_keys) do
              %w[
                spec.scenes.battle
                spec.fantasy.conversation
                spec.fantasy.inventory
              ]
            end

            it 'should define the expected scene pools' do
              expect(described_class.managed_scenes.keys)
                .to match_array(expected_keys)
            end

            include_deferred 'should manage scene',
              'Spec::Fantasy::Battle',
              type: 'spec.scenes.battle'

            include_deferred 'should manage scene',
              'Spec::Fantasy::Conversation'

            include_deferred 'should manage scene', 'Spec::Fantasy::Inventory'
          end

          context 'when the subclass manages scenes' do
            let(:expected_keys) do
              %w[
                spec.scenes.battle
                spec.dark_academia.tutorial
              ]
            end

            example_class 'Spec::DarkAcademia::Battle',   Ephesus::Core::Scene
            example_class 'Spec::DarkAcademia::Tutorial', Ephesus::Core::Scene

            before(:example) do
              Spec::EngineSubclass.manage_scene(
                Spec::DarkAcademia::Battle,
                scene_type: 'spec.scenes.battle'
              )

              Spec::EngineSubclass.manage_scene(Spec::DarkAcademia::Tutorial)
            end

            it 'should define the expected scene pools' do
              expect(described_class.managed_scenes.keys)
                .to match_array(expected_keys)
            end

            include_deferred 'should manage scene',
              'Spec::DarkAcademia::Battle',
              type: 'spec.scenes.battle'

            include_deferred 'should manage scene',
              'Spec::DarkAcademia::Tutorial'
          end

          context 'when the engine and the subclass manage scenes' do
            let(:expected_keys) do
              %w[
                spec.scenes.battle
                spec.fantasy.conversation
                spec.fantasy.inventory
                spec.dark_academia.tutorial
              ]
            end

            example_class 'Spec::DarkAcademia::Battle',   Ephesus::Core::Scene
            example_class 'Spec::DarkAcademia::Tutorial', Ephesus::Core::Scene

            before(:example) do
              Spec::EngineSubclass.manage_scene(
                Spec::DarkAcademia::Battle,
                scene_type: 'spec.scenes.battle'
              )

              Spec::EngineSubclass.manage_scene(Spec::DarkAcademia::Tutorial)
            end

            include_deferred 'when the engine manages scenes'

            it 'should define the expected scene pools' do
              expect(described_class.managed_scenes.keys)
                .to match_array(expected_keys)
            end

            include_deferred 'should manage scene',
              'Spec::DarkAcademia::Battle',
              type: 'spec.scenes.battle'

            include_deferred 'should manage scene',
              'Spec::DarkAcademia::Tutorial'

            include_deferred 'should manage scene',
              'Spec::Fantasy::Conversation'

            include_deferred 'should manage scene', 'Spec::Fantasy::Inventory'
          end
        end
      end

      describe '#default_scene' do
        next if example_options.fetch(:default_scene, false)

        it { expect(subject.send(:default_scene)).to be nil }
      end

      describe '#get_scene' do
        let(:options) { {} }

        describe 'with a non-matching scene class' do
          let(:scene_class) { Spec::InvalidScene }
          let(:error_message) do
            "unable to get scene #{scene_class.type.inspect} - no scene pool " \
              'matching the requested scene type'
          end

          example_class 'Spec::InvalidScene', Ephesus::Core::Scene

          it 'should raise an exception' do
            expect { subject.get_scene(scene_class) }.to raise_error(
              described_class::SceneNotFoundError,
              error_message
            )
          end
        end

        describe 'with a non-matching scene type' do
          let(:scene_type) { 'spec.invalid_type' }
          let(:error_message) do
            "unable to get scene #{scene_type.inspect} - no scene pool " \
              'matching the requested scene type'
          end

          it 'should raise an exception' do
            expect { subject.get_scene(scene_type) }.to raise_error(
              described_class::SceneNotFoundError,
              error_message
            )
          end

          it 'should not add a scene to #scenes' do # rubocop:disable RSpec/ExampleLength
            expect do
              subject.get_scene(scene_type)
            rescue described_class::SceneNotFoundError
              nil
            end
              .not_to(change { engine.send(:scenes) })
          end
        end

        wrap_deferred 'when the engine manages scenes' do
          describe 'with a non-matching scene type' do
            let(:scene_type) { 'spec.invalid_type' }
            let(:error_message) do
              "unable to get scene #{scene_type.inspect} - no scene pool " \
                'matching the requested scene type'
            end

            it 'should raise an exception' do
              expect { subject.get_scene(scene_type) }.to raise_error(
                described_class::SceneNotFoundError,
                error_message
              )
            end

            it 'should not add a scene to #scenes' do # rubocop:disable RSpec/ExampleLength
              expect do
                subject.get_scene(scene_type)
              rescue described_class::SceneNotFoundError
                nil
              end
                .not_to(change { engine.send(:scenes) })
            end
          end

          describe 'with a matching scene class' do
            let(:scene_class) { Spec::Fantasy::Conversation }

            it 'should return the matching scene' do
              expect(subject.get_scene(scene_class, **options))
                .to be_a Spec::Fantasy::Conversation
            end

            it 'should delegate to the scene pool' do
              scene_pool = subject.send(:scene_pools)[scene_class.type]

              allow(scene_pool).to receive(:get)

              subject.get_scene(scene_class, **options)

              expect(scene_pool).to have_received(:get).with(no_args)
            end

            it 'should add the scene to #scenes' do
              scene = subject.get_scene(scene_class, **options)

              expect(subject.send(:scenes)[scene.id]).to be scene
            end

            context 'when the scene is already added' do
              before(:example) { subject.get_scene(scene_class, **options) }

              it 'should not add a scene to #scenes' do
                expect { described_class::SceneNotFoundError }
                  .not_to(change { engine.send(:scenes) })
              end
            end

            describe 'with options: value' do
              let(:options) { super().merge(custom_property: 'custom value') }

              it 'should return the matching scene' do
                expect(subject.get_scene(scene_class, **options))
                  .to be_a Spec::Fantasy::Conversation
              end

              it 'should delegate to the scene pool' do
                scene_pool = subject.send(:scene_pools)[scene_class.type]

                allow(scene_pool).to receive(:get)

                subject.get_scene(scene_class, **options)

                expect(scene_pool).to have_received(:get).with(**options)
              end

              it 'should add the scene to #scenes' do
                scene = subject.get_scene(scene_class, **options)

                expect(subject.send(:scenes)[scene.id]).to be scene
              end

              context 'when the scene is already added' do
                before(:example) { subject.get_scene(scene_class, **options) }

                it 'should not add a scene to #scenes' do
                  expect { described_class::SceneNotFoundError }
                    .not_to(change { engine.send(:scenes) })
                end
              end
            end
          end

          describe 'with a matching scene type' do
            let(:scene_type) { 'spec.scenes.battle' }

            it 'should return the matching scene' do
              expect(subject.get_scene(scene_type, **options))
                .to be_a Spec::Fantasy::Battle
            end

            it 'should delegate to the scene pool' do
              scene_pool = subject.send(:scene_pools)[scene_type]

              allow(scene_pool).to receive(:get)

              subject.get_scene(scene_type, **options)

              expect(scene_pool).to have_received(:get).with(no_args)
            end

            it 'should add the scene to #scenes' do
              scene = subject.get_scene(scene_type, **options)

              expect(subject.send(:scenes)[scene.id]).to be scene
            end

            context 'when the scene is already added' do
              before(:example) { subject.get_scene(scene_type, **options) }

              it 'should not add a scene to #scenes' do
                expect { described_class::SceneNotFoundError }
                  .not_to(change { engine.send(:scenes) })
              end
            end

            describe 'with options: value' do
              let(:options) { super().merge(custom_property: 'custom value') }

              it 'should return the matching scene' do
                expect(subject.get_scene(scene_type, **options))
                  .to be_a Spec::Fantasy::Battle
              end

              it 'should delegate to the scene pool' do
                scene_pool = subject.send(:scene_pools)[scene_type]

                allow(scene_pool).to receive(:get)

                subject.get_scene(scene_type, **options)

                expect(scene_pool).to have_received(:get).with(**options)
              end

              it 'should add the scene to #scenes' do
                scene = subject.get_scene(scene_type, **options)

                expect(subject.send(:scenes)[scene.id]).to be scene
              end

              context 'when the scene is already added' do
                before(:example) { subject.get_scene(scene_type, **options) }

                it 'should not add a scene to #scenes' do
                  expect { described_class::SceneNotFoundError }
                    .not_to(change { engine.send(:scenes) })
                end
              end
            end
          end
        end
      end

      describe '#handle_scene_added' do
        let(:scene) { Ephesus::Core::Scene.new }
        let(:type)  { 'spec.custom' }
        let(:message) do
          Ephesus::Core::Scenes::Pool::SceneAdded.new(scene:, type:)
        end

        it 'should add the scene to #scenes', :aggregate_failures do
          expect { subject.handle_scene_added(message) }.to(
            change { subject.send(:scenes) }.to(have_key(scene.id))
          )

          expect(subject.send(:scenes)[scene.id]).to be scene
        end
      end

      describe '#scenes' do
        it { expect(subject.send(:scenes)).to be == {} }
      end

      describe '#scene_pools' do
        let(:scene_pools) { subject.send(:scene_pools) }

        it { expect(subject.send(:scene_pools)).to be == {} }

        wrap_deferred 'when the engine manages scenes' do
          let(:expected_keys) do
            %w[
              spec.scenes.battle
              spec.fantasy.conversation
              spec.fantasy.inventory
            ]
          end
          let(:expected_classes) do
            described_class.managed_scenes.values
          end

          it { expect(scene_pools.keys).to match_array(expected_keys) }

          it 'should initialize the scene pools' do
            expect(scene_pools.each_value.map(&:class))
              .to match_array(expected_classes)
          end
        end
      end
    end
  end
end
