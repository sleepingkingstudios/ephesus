# frozen_string_literal: true

require 'rspec/sleeping_king_studios/deferred'

require 'ephesus/core/rspec/deferred'

module Ephesus::Core::RSpec::Deferred
  # Deferred examples for testing scenes.
  module ScenesExamples
    include RSpec::SleepingKingStudios::Deferred::Provider

    deferred_context 'when the scene handles events' do
      example_class 'Spec::Commands::Pop',  Ephesus::Core::Command
      example_class 'Spec::Commands::Pull', Ephesus::Core::Command
      example_class 'Spec::Commands::Push', Ephesus::Core::Command

      before(:example) do
        Spec::CustomScene.handle_event(
          Spec::Commands::Pop,
          event_type: 'spec.events.pop'
        )

        Spec::CustomScene.handle_event(Spec::Commands::Pull)
        Spec::CustomScene.handle_event(Spec::Commands::Push)
      end
    end

    deferred_examples 'should handle event' do |command_class = nil, type: nil|
      # rubocop:disable RSpec/LeakyLocalVariable
      event_type = type || command_class
      event_type = event_type.type if event_type.respond_to?(:type)
      message    = "should define the #{event_type || 'event'} handler"
      # rubocop:enable RSpec/LeakyLocalVariable

      describe(message) do
        let(:expected_command) do
          next super() if defined?(super())

          expected = command_class
          expected = Object.const_get(expected) if expected.is_a?(String)
          expected
        end
        let(:expected_type) do
          next super() if defined?(super())

          event_type
        end

        specify do
          expect(described_class.handled_events.fetch(expected_type))
            .to be == expected_command
        end
      end
    end

    deferred_examples 'should implement the event handling interface' do
      describe '.handle_event' do
        it 'should define the class method' do
          expect(described_class)
            .to respond_to(:handle_event)
            .with(1).argument
            .and_keywords(:event_type, :force)
        end
      end

      describe '.handle_event?' do
        it 'should define the class method' do
          expect(described_class).to respond_to(:handle_event?).with(1).argument
        end
      end

      describe '.handled_events' do
        include_examples 'should define class reader', :handled_events
      end

      describe '#handle_event' do
        it { expect(scene).to respond_to(:handle_event, true).with(1).argument }
      end
    end

    deferred_examples 'should implement the event handling methods' do
      describe '.handle_event' do
        deferred_examples 'should register the event handler' do
          let(:expected_type) do
            expected = options.fetch(:event_type, command_class)
            expected = expected.type if expected.respond_to?(:type)
            expected.to_s
          end

          it { expect(handle_event).to be == expected_type }

          context 'when the event is registered' do
            before(:example) { handle_event }

            include_deferred 'should handle event', 'Spec::CustomCommand'
          end
        end

        let(:command_class) { Spec::CustomCommand }
        let(:options)       { {} }

        example_class 'Spec::CustomCommand', Ephesus::Core::Command

        define_method :handle_event do
          described_class.handle_event(command_class, **options)
        end

        define_method :tools do
          SleepingKingStudios::Tools::Toolbelt.instance
        end

        describe 'with nil' do
          let(:command_class) { nil }
          let(:error_message) do
            tools.assertions.error_message_for(:class, as: 'command_class')
          end

          it 'should raise an exception' do
            expect { handle_event }.to raise_error ArgumentError, error_message
          end
        end

        describe 'with an Object' do
          let(:command_class) { Object.new.freeze }
          let(:error_message) do
            tools.assertions.error_message_for(:class, as: 'command_class')
          end

          it 'should raise an exception' do
            expect { handle_event }.to raise_error ArgumentError, error_message
          end
        end

        describe 'with a Class' do
          let(:command_class) { Class.new }
          let(:error_message) do
            tools.assertions.error_message_for(
              :inherit_from,
              expected: Ephesus::Core::Command,
              as:       'command_class'
            )
          end

          it 'should raise an exception' do
            expect { handle_event }.to raise_error ArgumentError, error_message
          end
        end

        describe 'with a command class' do
          include_deferred 'should register the event handler'
        end

        describe 'with a command class and event_type: nil' do
          let(:options) { super().merge(event_type: nil) }
          let(:error_message) do
            tools.assertions.error_message_for(:presence, as: 'event_type')
          end

          it 'should raise an exception' do
            expect { handle_event }.to raise_error ArgumentError, error_message
          end
        end

        describe 'with a command class and event_type: an Object' do
          let(:options) { super().merge(event_type: Object.new.freeze) }
          let(:error_message) do
            tools.assertions.error_message_for(:name, as: 'event_type')
          end

          it 'should raise an exception' do
            expect { handle_event }.to raise_error ArgumentError, error_message
          end
        end

        describe 'with a command class and event_type: an empty String' do
          let(:options) { super().merge(event_type: '') }
          let(:error_message) do
            tools.assertions.error_message_for(:presence, as: 'event_type')
          end

          it 'should raise an exception' do
            expect { handle_event }.to raise_error ArgumentError, error_message
          end
        end

        describe 'with a command class and event_type: an invalid String' do
          let(:options) { super().merge(event_type: 'InvalidEvent') }
          let(:error_message) do
            'event_type must be a lowercase underscored string separated by ' \
              'periods'
          end

          it 'should raise an exception' do
            expect { handle_event }.to raise_error ArgumentError, error_message
          end
        end

        describe 'with a command class and event_type: an invalid Symbol' do
          let(:options) { super().merge(event_type: :InvalidEvent) }
          let(:error_message) do
            'event_type must be a lowercase underscored string separated by ' \
              'periods'
          end

          it 'should raise an exception' do
            expect { handle_event }.to raise_error ArgumentError, error_message
          end
        end

        describe 'with a command class and event_type: an empty Symbol' do
          let(:options) { super().merge(event_type: :'') }
          let(:error_message) do
            tools.assertions.error_message_for(:presence, as: 'event_type')
          end

          it 'should raise an exception' do
            expect { handle_event }.to raise_error ArgumentError, error_message
          end
        end

        describe 'with a command class and event_type: an Event class' do
          let(:options) { super().merge(event_type: Spec::Scoped::CustomEvent) }

          example_constant 'Spec::Scoped::CustomEvent' do
            Ephesus::Core::Message.define
          end

          include_deferred 'should register the event handler'
        end

        describe 'with a command class and event_type: a valid String' do
          let(:options) { super().merge(event_type: 'spec.scoped.custom') }

          include_deferred 'should register the event handler'
        end

        describe 'with a command class and event_type: a valid Symbol' do
          let(:options) { super().merge(event_type: :'spec.scoped.custom') }

          include_deferred 'should register the event handler'
        end

        context 'when the class is abstract' do
          let(:error_message) do
            'unable to add event handler for abstract class ' \
              "#{described_class.name}"
          end

          before(:example) do
            Spec::CustomScene.define_singleton_method(:abstract?) { true }
          end

          it 'should raise an exception' do
            expect { described_class.handle_event(command_class) }
              .to raise_error described_class::AbstractClassError, error_message
          end

          describe 'with force: true' do
            it 'should register the event handler' do
              described_class.handle_event(command_class, force: true)

              expect(described_class.handled_events[command_class.type])
                .to be command_class
            end
          end
        end
      end

      describe '.handle_event?' do
        describe 'with nil' do
          it { expect(described_class.handle_event?(nil)).to be false }
        end

        describe 'with an Object' do
          let(:event) { Object.new.freeze }

          it { expect(described_class.handle_event?(event)).to be false }
        end

        describe 'with an empty String' do
          it { expect(described_class.handle_event?('')).to be false }
        end

        describe 'with an empty Symbol' do
          it { expect(described_class.handle_event?(:'')).to be false }
        end

        describe 'with an unhandled Command class' do
          let(:command_class) { Spec::CustomCommand }

          example_class 'Spec::CustomCommand', Ephesus::Core::Command

          specify do
            expect(described_class.handle_event?(command_class)).to be false
          end
        end

        describe 'with an unhandled Event' do
          let(:event) { Spec::CustomEvent.new }

          example_constant 'Spec::CustomEvent' do
            Ephesus::Core::Message.define
          end

          it { expect(described_class.handle_event?(event)).to be false }
        end

        describe 'with an unhandled Event class' do
          let(:event_class) { Spec::CustomEvent }

          example_constant 'Spec::CustomEvent' do
            Ephesus::Core::Message.define
          end

          it { expect(described_class.handle_event?(event_class)).to be false }
        end

        describe 'with an unhandled String' do
          let(:event_type) { 'spec.custom' }

          it { expect(described_class.handle_event?(event_type)).to be false }
        end

        describe 'with an unhandled Symbol' do
          let(:event_type) { :'spec.custom' }

          it { expect(described_class.handle_event?(event_type)).to be false }
        end

        describe 'with a subclass of the scene' do
          let(:parent_class)    { Spec::CustomScene }
          let(:described_class) { Spec::SceneSubclass }

          example_class 'Spec::SceneSubclass', 'Spec::CustomScene'

          include_deferred 'when the scene handles events'

          describe 'with an unhandled Command class' do
            let(:command_class) { Spec::CustomCommand }

            example_class 'Spec::CustomCommand', Ephesus::Core::Command

            specify do
              expect(described_class.handle_event?(command_class)).to be false
            end
          end

          describe 'with a handled Command Class' do
            let(:command_class) { Spec::Commands::Push }

            specify do
              expect(described_class.handle_event?(command_class)).to be true
            end
          end

          describe 'with an unhandled Event' do
            let(:event) { Spec::CustomEvent.new }

            example_constant 'Spec::CustomEvent' do
              Ephesus::Core::Message.define
            end

            it { expect(described_class.handle_event?(event)).to be false }
          end

          describe 'with a handled event' do
            let(:event) { Spec::Commands::Push::Event.new }

            example_constant 'Spec::Commands::Push::Event' do
              Ephesus::Core::Message.define
            end

            it { expect(described_class.handle_event?(event)).to be true }
          end

          describe 'with an unhandled Event class' do
            let(:event_class) { Spec::CustomEvent }

            example_constant 'Spec::CustomEvent' do
              Ephesus::Core::Message.define
            end

            specify do
              expect(described_class.handle_event?(event_class)).to be false
            end
          end

          describe 'with a handled event class' do
            let(:event_class) { Spec::Commands::Push::Event }

            example_constant 'Spec::Commands::Push::Event' do
              Ephesus::Core::Message.define
            end

            it { expect(described_class.handle_event?(event_class)).to be true }
          end

          describe 'with an unhandled String' do
            let(:event_type) { 'spec.custom' }

            it { expect(described_class.handle_event?(event_type)).to be false }
          end

          describe 'with a handled String' do
            let(:event_type) { 'spec.events.pop' }

            it { expect(described_class.handle_event?(event_type)).to be true }
          end

          describe 'with an unhandled Symbol' do
            let(:event_type) { :'spec.custom' }

            it { expect(described_class.handle_event?(event_type)).to be false }
          end

          describe 'with a handled Symbol' do
            let(:event_type) { :'spec.events.pop' }

            it { expect(described_class.handle_event?(event_type)).to be true }
          end
        end
      end

      describe '.handled_events' do
        let(:default_event_handlers) do
          next super() if defined?(super())

          {}
        end
        let(:expected) { default_event_handlers }

        it { expect(described_class.handled_events).to be == expected }

        wrap_deferred 'when the scene handles events' do
          let(:expected) do
            super().merge(
              'spec.commands.pull' => Spec::Commands::Pull,
              'spec.commands.push' => Spec::Commands::Push,
              'spec.events.pop'    => Spec::Commands::Pop
            )
          end

          it { expect(described_class.handled_events).to be == expected }
        end

        describe 'with a subclass of the scene' do
          let(:parent_class)    { Spec::CustomScene }
          let(:described_class) { Spec::SceneSubclass }

          example_class 'Spec::SceneSubclass', 'Spec::CustomScene'

          it { expect(described_class.handled_events).to be == expected }

          wrap_deferred 'when the scene handles events' do
            let(:expected) do
              super().merge(
                'spec.commands.pull' => Spec::Commands::Pull,
                'spec.commands.push' => Spec::Commands::Push,
                'spec.events.pop'    => Spec::Commands::Pop
              )
            end

            it { expect(described_class.handled_events).to be == expected }
          end

          context 'when the subclass handles events' do
            let(:expected) do
              super().merge(
                'spec.balloons.inflate' => Spec::Balloons::Inflate,
                'spec.events.pop'       => Spec::Balloons::Pop
              )
            end

            example_class 'Spec::Balloons::Inflate', Ephesus::Core::Command
            example_class 'Spec::Balloons::Pop',     Ephesus::Core::Command

            before(:example) do
              Spec::SceneSubclass.handle_event(
                Spec::Balloons::Pop,
                event_type: 'spec.events.pop'
              )

              Spec::SceneSubclass.handle_event Spec::Balloons::Inflate
            end

            it { expect(described_class.handled_events).to be == expected }
          end

          context 'when the scene and subclass handle events' do
            let(:expected) do
              super().merge(
                'spec.balloons.inflate' => Spec::Balloons::Inflate,
                'spec.commands.pull'    => Spec::Commands::Pull,
                'spec.commands.push'    => Spec::Commands::Push,
                'spec.events.pop'       => Spec::Balloons::Pop
              )
            end

            example_class 'Spec::Balloons::Inflate', Ephesus::Core::Command
            example_class 'Spec::Balloons::Pop',     Ephesus::Core::Command

            before(:example) do
              Spec::SceneSubclass.handle_event(
                Spec::Balloons::Pop,
                event_type: 'spec.events.pop'
              )

              Spec::SceneSubclass.handle_event Spec::Balloons::Inflate
            end

            include_deferred 'when the scene handles events'

            it { expect(described_class.handled_events).to be == expected }
          end
        end
      end

      describe '#handle_event' do
        let(:event) { Spec::CustomEvent.new(message: 'Ad astra!') }

        example_constant 'Spec::CustomEvent' do
          Ephesus::Core::Message.define(:message)
        end

        describe 'with an unhandled event' do
          let(:error_message) do
            event_data = event.to_h.inspect

            "no event handler found for event #{event.type} (#{event_data})"
          end

          it 'should raise an exception' do
            expect { scene.send(:handle_event, event) }.to raise_error(
              described_class::UnhandledEventError,
              error_message
            )
          end
        end

        context 'when the scene handles the event' do
          let(:command_class)  { Spec::CustomCommand }
          let(:implementation) { ->(**) {} }
          let(:side_effects)   { [] }

          example_class 'Spec::CustomCommand', Ephesus::Core::Command do |klass|
            klass.define_method(:process, &implementation)
          end

          before(:example) do
            described_class.handle_event(command_class, event_type: event)

            allow(scene).to receive(:handle_side_effect) \
            do |side_effect, details|
              side_effects << [side_effect, *details]
            end
          end

          it 'should initialize the command' do
            allow(command_class).to receive(:new).and_call_original

            scene.send(:handle_event, event)

            expect(command_class).to have_received(:new).with(no_args)
          end

          it 'should call the command with the event and state' do # rubocop:disable RSpec/ExampleLength
            mock_result  = Cuprum::Result.new(value: scene.state)
            mock_command = instance_double(command_class, call: mock_result)

            allow(command_class).to receive(:new).and_return(mock_command)

            scene.send(:handle_event, event)

            expect(mock_command)
              .to have_received(:call)
              .with(event:, state: scene.state)
          end

          context 'when the command returns a passing result' do
            let(:implementation) { ->(**) { { ok: true } } }
            let(:expected_value) { { ok: true } }

            it 'should return a passing result' do
              expect(scene.send(:handle_event, event))
                .to be_a_passing_result
                .with_value(expected_value)
            end

            it 'should not update the scene state' do
              expect { scene.send(:handle_event, event) }.not_to(
                change { scene.state.to_h }
              )
            end

            it 'should not handle any side effects' do
              scene.send(:handle_event, event)

              expect(side_effects).to be == []
            end

            context 'when the result has a state' do
              let(:implementation) do
                state =
                  Ephesus::Core::State
                  .new(scene.state.to_h)
                  .set('checksum', value: 0xdeadbeef)

                ->(**) { state }
              end
              let!(:expected_state) do
                scene.state.to_h.merge('checksum' => 0xdeadbeef)
              end
              let(:expected_value) { Ephesus::Core::State.new(expected_state) }

              it 'should update the scene state' do
                expect { scene.send(:handle_event, event) }.to(
                  change { scene.state.to_h }.to(be == expected_state)
                )
              end

              it 'should not handle any side effects' do
                scene.send(:handle_event, event)

                expect(side_effects).to be == []
              end
            end

            context 'when the result has a state and side effects' do
              let(:implementation) do
                state =
                  Ephesus::Core::State
                  .new(scene.state.to_h)
                  .set('checksum', value: 0xdeadbeef)

                lambda do |**|
                  @state = state

                  side_effects << [:do_something]
                  side_effects << [:greet, 'programs']

                  success
                end
              end
              let!(:expected_state) do
                scene.state.to_h.merge('checksum' => 0xdeadbeef)
              end
              let(:expected_side_effects) do
                [
                  %i[do_something],
                  [:greet, 'programs']
                ]
              end

              it 'should update the scene state' do
                expect { scene.send(:handle_event, event) }.to(
                  change { scene.state.to_h }.to(be == expected_state)
                )
              end

              it 'should handle the side effects' do
                scene.send(:handle_event, event)

                expect(side_effects).to be == expected_side_effects
              end
            end

            context 'when the result has only side effects' do
              let(:implementation) do
                lambda do |**|
                  side_effects << [:do_something]
                  side_effects << [:greet, 'programs']

                  success(side_effects)
                end
              end
              let(:expected_side_effects) do
                [
                  %i[do_something],
                  [:greet, 'programs']
                ]
              end

              it 'should not update the scene state' do
                expect { scene.send(:handle_event, event) }.not_to(
                  change { scene.state.to_h }
                )
              end

              it 'should handle the side effects' do
                scene.send(:handle_event, event)

                expect(side_effects).to be == expected_side_effects
              end
            end
          end

          context 'when the command returns a failing result' do
            let(:implementation) do
              error = expected_error

              ->(**) { failure(error) }
            end
            let(:expected_error) do
              Cuprum::Error.new(message: 'Something went wrong.')
            end

            it 'should return a failing result' do
              expect(scene.send(:handle_event, event))
                .to be_a_failing_result
                .with_error(expected_error)
            end

            it 'should not handle any side effects' do
              scene.send(:handle_event, event)

              expect(side_effects).to be == []
            end

            context 'when the result has a state' do
              let(:implementation) do
                error = expected_error
                state =
                  Ephesus::Core::State
                  .new(scene.state.to_h)
                  .set('checksum', value: 0xdeadbeef)

                ->(**) { Cuprum::Result.new(value: state, error:) }
              end
              let!(:expected_state) do
                scene.state.to_h.merge('checksum' => 0xdeadbeef)
              end
              let(:expected_value) { Ephesus::Core::State.new(expected_state) }

              it 'should return a failing result' do
                expect(scene.send(:handle_event, event))
                  .to be_a_failing_result
                  .with_value(expected_value)
                  .and_error(expected_error)
              end

              it 'should not update the scene state' do
                expect { scene.send(:handle_event, event) }.not_to(
                  change { scene.state.to_h }
                )
              end

              it 'should not handle any side effects' do
                scene.send(:handle_event, event)

                expect(side_effects).to be == []
              end
            end

            context 'when the result has a state and side effects' do
              let(:implementation) do
                error = expected_error
                state =
                  Ephesus::Core::State
                  .new(scene.state.to_h)
                  .set('checksum', value: 0xdeadbeef)

                lambda do |**|
                  @state = state

                  side_effects << [:do_something]
                  side_effects << [:greet, 'programs']

                  Cuprum::Result.new(value: [state, *side_effects], error:)
                end
              end
              let(:expected_side_effects) do
                [
                  %i[do_something],
                  [:greet, 'programs']
                ]
              end

              it 'should not update the scene state' do
                expect { scene.send(:handle_event, event) }.not_to(
                  change { scene.state.to_h }
                )
              end

              it 'should handle the side effects' do
                scene.send(:handle_event, event)

                expect(side_effects).to be == expected_side_effects
              end
            end

            context 'when the result has only side effects' do
              let(:implementation) do
                error = expected_error

                lambda do |**|
                  side_effects << [:do_something]
                  side_effects << [:greet, 'programs']

                  Cuprum::Result.new(value: [state, *side_effects], error:)
                end
              end
              let(:expected_side_effects) do
                [
                  %i[do_something],
                  [:greet, 'programs']
                ]
              end

              it 'should not update the scene state' do
                expect { scene.send(:handle_event, event) }.not_to(
                  change { scene.state.to_h }
                )
              end

              it 'should handle the side effects' do
                scene.send(:handle_event, event)

                expect(side_effects).to be == expected_side_effects
              end
            end
          end
        end
      end
    end
  end
end
