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
