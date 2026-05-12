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

    deferred_context 'when the scene handles the event' do
      let(:processed_events) { [] }

      example_class 'Spec::AddCommand', Ephesus::Core::Command do |klass|
        events = processed_events

        klass.const_set(:Event, Ephesus::Core::Message.define(:amount))

        klass.define_method(:process) do |event:, **|
          events << event

          event.amount.times do
            push_event(Spec::IncrementCommand::Event.new)
          end

          success
        end
      end

      example_class 'Spec::IncrementCommand', Ephesus::Core::Command \
      do |klass|
        events = processed_events

        klass.const_set(:Event, Ephesus::Core::Message.define)

        klass.define_method(:process) do |event:, state:, **|
          events << event

          state.set('value', value: state.fetch('value', default: 0) + 1)
        end
      end

      example_class 'Spec::MultiplyCommand', Ephesus::Core::Command \
      do |klass|
        events = processed_events

        klass.const_set(:Event, Ephesus::Core::Message.define(:amount))

        klass.define_method(:process) do |event:, state:|
          events << event

          (event.amount - 1).times do
            push_event(Spec::AddCommand::Event.new(state.get('value')))
          end

          success
        end
      end

      before(:example) do
        described_class.handle_event Spec::AddCommand
        described_class.handle_event Spec::IncrementCommand
        described_class.handle_event Spec::MultiplyCommand
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
        it 'should define the private method' do
          expect(subject).to respond_to(:handle_event, true).with(1).argument
        end
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
            expect { subject.send(:handle_event, event) }.to raise_error(
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

            allow(subject).to receive(:handle_side_effect) \
            do |side_effect, details|
              side_effects << [side_effect, *details]
            end
          end

          it 'should initialize the command' do
            allow(command_class).to receive(:new).and_call_original

            subject.send(:handle_event, event)

            expect(command_class).to have_received(:new).with(no_args)
          end

          it 'should call the command with the event and state' do # rubocop:disable RSpec/ExampleLength
            mock_result  = Cuprum::Result.new(value: subject.state)
            mock_command = instance_double(command_class, call: mock_result)

            allow(command_class).to receive(:new).and_return(mock_command)

            subject.send(:handle_event, event)

            expect(mock_command)
              .to have_received(:call)
              .with(event:, state: subject.state)
          end

          context 'when the command returns a passing result' do
            let(:implementation) { ->(**) { { ok: true } } }
            let(:expected_value) { { ok: true } }

            it 'should return a passing result' do
              expect(subject.send(:handle_event, event))
                .to be_a_passing_result
                .with_value(expected_value)
            end

            it 'should not update the scene state' do
              expect { subject.send(:handle_event, event) }.not_to(
                change { subject.state.to_h }
              )
            end

            it 'should not handle any side effects' do
              subject.send(:handle_event, event)

              expect(side_effects).to be == []
            end

            context 'when the result has a state' do
              let(:implementation) do
                state =
                  Ephesus::Core::State
                  .new(subject.state.to_h)
                  .set('checksum', value: 0xdeadbeef)

                ->(**) { state }
              end
              let!(:expected_state) do
                subject.state.to_h.merge('checksum' => 0xdeadbeef)
              end
              let(:expected_value) { Ephesus::Core::State.new(expected_state) }

              it 'should update the scene state' do
                expect { subject.send(:handle_event, event) }.to(
                  change { subject.state.to_h }.to(be == expected_state)
                )
              end

              it 'should not handle any side effects' do
                subject.send(:handle_event, event)

                expect(side_effects).to be == []
              end
            end

            context 'when the result has a state and side effects' do
              let(:implementation) do
                state =
                  Ephesus::Core::State
                  .new(subject.state.to_h)
                  .set('checksum', value: 0xdeadbeef)

                lambda do |**|
                  @state = state

                  side_effects << [:do_something]
                  side_effects << [:greet, 'programs']

                  success
                end
              end
              let!(:expected_state) do
                subject.state.to_h.merge('checksum' => 0xdeadbeef)
              end
              let(:expected_side_effects) do
                [
                  %i[do_something],
                  [:greet, 'programs']
                ]
              end

              it 'should update the scene state' do
                expect { subject.send(:handle_event, event) }.to(
                  change { subject.state.to_h }.to(be == expected_state)
                )
              end

              it 'should handle the side effects' do
                subject.send(:handle_event, event)

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
                expect { subject.send(:handle_event, event) }.not_to(
                  change { subject.state.to_h }
                )
              end

              it 'should handle the side effects' do
                subject.send(:handle_event, event)

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
              expect(subject.send(:handle_event, event))
                .to be_a_failing_result
                .with_error(expected_error)
            end

            it 'should not handle any side effects' do
              subject.send(:handle_event, event)

              expect(side_effects).to be == []
            end

            context 'when the result has a state' do
              let(:implementation) do
                error = expected_error
                state =
                  Ephesus::Core::State
                  .new(subject.state.to_h)
                  .set('checksum', value: 0xdeadbeef)

                ->(**) { Cuprum::Result.new(value: state, error:) }
              end
              let!(:expected_state) do
                subject.state.to_h.merge('checksum' => 0xdeadbeef)
              end
              let(:expected_value) { Ephesus::Core::State.new(expected_state) }

              it 'should return a failing result' do
                expect(subject.send(:handle_event, event))
                  .to be_a_failing_result
                  .with_value(expected_value)
                  .and_error(expected_error)
              end

              it 'should not update the scene state' do
                expect { subject.send(:handle_event, event) }.not_to(
                  change { subject.state.to_h }
                )
              end

              it 'should not handle any side effects' do
                subject.send(:handle_event, event)

                expect(side_effects).to be == []
              end
            end

            context 'when the result has a state and side effects' do
              let(:implementation) do
                error = expected_error
                state =
                  Ephesus::Core::State
                  .new(subject.state.to_h)
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
                expect { subject.send(:handle_event, event) }.not_to(
                  change { subject.state.to_h }
                )
              end

              it 'should handle the side effects' do
                subject.send(:handle_event, event)

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
                expect { subject.send(:handle_event, event) }.not_to(
                  change { subject.state.to_h }
                )
              end

              it 'should handle the side effects' do
                subject.send(:handle_event, event)

                expect(side_effects).to be == expected_side_effects
              end
            end
          end
        end
      end
    end

    deferred_examples 'should implement the event processing interface' do
      describe '#enqueue_event' do
        it { expect(subject).to respond_to(:enqueue_event).with(1).argument }

        it 'should alias the method' do
          expect(subject).to have_aliased_method(:enqueue_event).as(:enqueue)
        end
      end

      describe '#event_queue' do
        include_examples 'should define private reader', :event_queue
      end

      describe '#event_stack' do
        include_examples 'should define private reader', :event_stack
      end

      describe '#call' do
        it 'should define the method' do
          expect(subject)
            .to respond_to(:call)
            .with(0).arguments
            .and_keywords(:batch_size, :thread_safe)
        end
      end

      describe '#processing?' do
        include_examples 'should define predicate', :processing?
      end
    end

    deferred_examples 'should implement the event processing methods' do
      describe '#enqueue_event' do
        let(:event) { Ephesus::Core::Message.new }

        define_method :queued_events do
          queue  = subject.send(:event_queue)
          events = []

          events << queue.pop until queue.empty?

          events
        end

        it 'should push the event onto the events queue', :aggregate_failures do
          expect { subject.enqueue_event(event) }.to(
            change { subject.send(:event_queue).size }.to(be 1)
          )

          expect(queued_events).to contain_exactly(event)
        end
      end

      describe '#event_queue' do
        it 'should return an empty queue' do
          expect(subject.send(:event_queue))
            .to be_a(Thread::Queue)
            .and have_attributes(empty?: true)
        end
      end

      describe '#event_stack' do
        it { expect(subject.send(:event_stack)).to be == [] }
      end

      describe '#call' do
        let(:options) { {} }

        define_method :process_events do
          subject.call(**options)
        end

        define_method :queued_events do
          queue  = subject.send(:event_queue)
          events = []

          events << queue.pop until queue.empty?

          events
        end

        context 'when there are no queued events' do
          it { expect(process_events).to be false }
        end

        context 'when there is one queued event' do
          let(:event) { Spec::IncrementCommand::Event.new }

          before(:example) { subject.enqueue_event(event) }

          include_deferred 'when the scene handles the event'

          it { expect(process_events).to be true }

          it 'should process the event' do
            process_events

            expect(processed_events).to be == [event]
          end

          it 'should update the state' do
            process_events

            expect(scene.state.get('value')).to be 1
          end

          it 'should remove the event from the queue', :aggregate_failures do
            expect { process_events }.to(
              change { scene.send(:event_queue).size }.by(-1)
            )

            expect(queued_events).to be == []
          end

          describe 'with thread_safe: false' do
            let(:options) { super().merge(thread_safe: false) }

            it { expect(process_events).to be true }

            it 'should process the event' do
              process_events

              expect(processed_events).to be == [event]
            end

            it 'should update the state' do
              process_events

              expect(scene.state.get('value')).to be 1
            end

            it 'should remove the event from the queue', :aggregate_failures do
              expect { process_events }.to(
                change { scene.send(:event_queue).size }.by(-1)
              )

              expect(queued_events).to be == []
            end
          end

          context 'when the scene is already processing events' do
            before(:example) do
              allow(subject).to receive(:processing?).and_return(true)
            end

            it { expect(process_events).to be false }

            it 'should not process the event' do
              process_events

              expect(processed_events).to be == []
            end

            it 'should not update the state' do
              process_events

              expect(scene.state.get('value')).to be nil
            end

            it 'should not remove the event from the queue' do
              expect { process_events }.not_to(
                change { scene.send(:event_queue).size }
              )
            end
          end
        end

        context 'when there are many queued events' do
          let(:events) { Array.new(3) { Spec::IncrementCommand::Event.new } }

          before(:example) do
            events.each { |event| subject.enqueue_event(event) }
          end

          include_deferred 'when the scene handles the event'

          it { expect(process_events).to be true }

          it 'should process the next event' do
            process_events

            expect(processed_events).to be == [events.first]
          end

          it 'should update the state' do
            process_events

            expect(scene.state.get('value')).to be 1
          end

          it 'should remove the next event from the queue',
            :aggregate_failures \
          do
            expect { process_events }.to(
              change { scene.send(:event_queue).size }.by(-1)
            )

            expect(queued_events).to be == events[1..]
          end

          describe 'with batch_size: value' do
            let(:options) { super().merge(batch_size: 2) }

            it { expect(process_events).to be true }

            it 'should process the specified number of events' do
              process_events

              expect(processed_events).to be == events[..1]
            end

            it 'should update the state' do
              process_events

              expect(scene.state.get('value')).to be 2
            end

            it 'should remove the processed events from the queue',
              :aggregate_failures \
            do
              expect { process_events }.to(
                change { scene.send(:event_queue).size }.by(-2)
              )

              expect(queued_events).to be == events[2..]
            end
          end

          describe 'with thread_safe: false' do
            let(:options) { super().merge(thread_safe: false) }

            it { expect(process_events).to be true }

            it 'should process the next event' do
              process_events

              expect(processed_events).to be == [events.first]
            end

            it 'should update the state' do
              process_events

              expect(scene.state.get('value')).to be 1
            end

            it 'should remove the next event from the queue',
              :aggregate_failures \
            do
              expect { process_events }.to(
                change { scene.send(:event_queue).size }.by(-1)
              )

              expect(queued_events).to be == events[1..]
            end
          end
        end

        context 'when the environment is multi-threaded' do
          let(:events) do
            [
              Spec::AddCommand::Event.new(amount: 1),
              Spec::AddCommand::Event.new(amount: 2),
              Spec::AddCommand::Event.new(amount: 3)
            ]
          end

          define_method :process_events do
            Array
              .new(3) { Thread.new { subject.call(**options) } }
              .map(&:join)
          end

          before(:example) do
            # Force thread to yield mid-function.
            allow(subject.send(:event_queue))
              .to receive(:empty?)
              .and_wrap_original do |original|
                sleep 0

                original.call
              end

            events.each { |event| subject.enqueue_event(event) }

            Spec::AddCommand.define_method(:process) do |event:, **|
              value = state.fetch('value', default: 0) + event.amount

              sleep 0

              state.set('value', value:)
            end
          end

          include_deferred 'when the scene handles the event'

          it 'should update the state', :aggregate_failures do
            process_events

            expect(scene.state.get('value')).to be 6
          end

          describe 'with thread_safe: false' do
            let(:options) { super().merge(thread_safe: false) }

            it 'should update the state', :aggregate_failures do
              process_events

              expect(scene.state.get('value'))
                .to(satisfy { |value| (1..3).cover?(value) })
            end
          end
        end
      end

      describe '#process_events' do
        deferred_examples 'should flag the scene as processing events' do
          let(:event)    { Spec::CheckProcessing::Event.new }
          let(:captured) { Struct.new(:processing).new }

          example_class 'Spec::CheckProcessing', Ephesus::Core::Command \
          do |klass|
            current_scene = subject
            scene_status  = captured

            klass.const_set(:Event, Ephesus::Core::Message.define)

            klass.define_method(:process) do |**|
              scene_status.processing = current_scene.processing?

              success
            end
          end

          before(:example) do
            described_class.handle_event Spec::CheckProcessing
          end

          it 'should flag the scene as processing events', :aggregate_failures \
          do
            expect(subject.processing?).to be false

            process_events

            expect(subject.processing?).to be false
            expect(captured.processing).to be true
          end
        end

        let(:options) { {} }

        define_method :process_events do
          subject.send(:process_events, **options)
        end

        define_method :queued_events do
          queue  = subject.send(:event_queue)
          events = []

          events << queue.pop until queue.empty?

          events
        end

        it 'should define the private method' do
          expect(scene)
            .to respond_to(:process_events, true)
            .with(0).arguments
            .and_keywords(:batch_size)
        end

        context 'when there are no queued events' do
          it { expect(process_events).to be false }
        end

        context 'when there is one queued event' do
          let(:event) { Spec::IncrementCommand::Event.new }

          before(:example) { subject.enqueue_event(event) }

          include_deferred 'when the scene handles the event'

          it { expect(process_events).to be true }

          it 'should process the event' do
            process_events

            expect(processed_events).to be == [event]
          end

          it 'should update the state' do
            process_events

            expect(scene.state.get('value')).to be 1
          end

          it 'should remove the event from the queue', :aggregate_failures do
            expect { process_events }.to(
              change { scene.send(:event_queue).size }.by(-1)
            )

            expect(queued_events).to be == []
          end

          wrap_deferred 'should flag the scene as processing events'

          describe 'with batch_size: value' do
            let(:options) { super().merge(batch_size: 2) }

            it { expect(process_events).to be true }

            it 'should process the event' do
              process_events

              expect(processed_events).to be == [event]
            end

            it 'should update the state' do
              process_events

              expect(scene.state.get('value')).to be 1
            end

            it 'should remove the event from the queue', :aggregate_failures do
              expect { process_events }.to(
                change { scene.send(:event_queue).size }.by(-1)
              )

              expect(queued_events).to be == []
            end
          end
        end

        context 'when there are many queued events' do
          let(:events) { Array.new(3) { Spec::IncrementCommand::Event.new } }

          before(:example) do
            events.each { |event| subject.enqueue_event(event) }
          end

          include_deferred 'when the scene handles the event'

          it { expect(process_events).to be true }

          it 'should process the next event' do
            process_events

            expect(processed_events).to be == [events.first]
          end

          it 'should update the state' do
            process_events

            expect(scene.state.get('value')).to be 1
          end

          it 'should remove the next event from the queue',
            :aggregate_failures \
          do
            expect { process_events }.to(
              change { scene.send(:event_queue).size }.by(-1)
            )

            expect(queued_events).to be == events[1..]
          end

          describe 'with batch_size: less than queue size' do
            let(:options) { super().merge(batch_size: 2) }

            it { expect(process_events).to be true }

            it 'should process the specified number of events' do
              process_events

              expect(processed_events).to be == events[..1]
            end

            it 'should update the state' do
              process_events

              expect(scene.state.get('value')).to be 2
            end

            it 'should remove the processed events from the queue',
              :aggregate_failures \
            do
              expect { process_events }.to(
                change { scene.send(:event_queue).size }.by(-2)
              )

              expect(queued_events).to be == events[2..]
            end
          end

          describe 'with batch_size: greater than or equal to queue size' do
            let(:options) { super().merge(batch_size: 4) }

            it { expect(process_events).to be true }

            it 'should process the specified number of events' do
              process_events

              expect(processed_events).to be == events
            end

            it 'should update the state' do
              process_events

              expect(scene.state.get('value')).to be 3
            end

            it 'should remove the processed events from the queue',
              :aggregate_failures \
            do
              expect { process_events }.to(
                change { scene.send(:event_queue).size }.by(-3)
              )

              expect(queued_events).to be == []
            end
          end
        end

        context 'when the handled events push events onto the stack' do
          let(:events) do
            [
              Spec::AddCommand::Event.new(amount: 2),
              Spec::MultiplyCommand::Event.new(amount: 3),
              Spec::AddCommand::Event.new(amount: 4)
            ]
          end
          let(:expected_events) do
            [
              Spec::AddCommand::Event.new(amount: 2),
              Spec::IncrementCommand::Event.new,
              Spec::IncrementCommand::Event.new
            ]
          end

          before(:example) do
            events.each { |event| subject.enqueue_event(event) }
          end

          include_deferred 'when the scene handles the event'

          it { expect(process_events).to be true }

          it 'should process the next event and stacked events' do
            process_events

            expect(processed_events).to be == expected_events
          end

          it 'should update the state' do
            process_events

            expect(scene.state.get('value')).to be 2
          end

          it 'should remove the next event from the queue',
            :aggregate_failures \
          do
            expect { process_events }.to(
              change { scene.send(:event_queue).size }.by(-1)
            )

            expect(queued_events).to be == events[1..]
          end

          describe 'with batch_size: less than event count for next event' do
            let(:options) { super().merge(batch_size: 2) }

            it { expect(process_events).to be true }

            it 'should process the next event and stacked events' do
              process_events

              expect(processed_events).to be == expected_events
            end

            it 'should update the state' do
              process_events

              expect(scene.state.get('value')).to be 2
            end

            it 'should remove the next event from the queue',
              :aggregate_failures \
            do
              expect { process_events }.to(
                change { scene.send(:event_queue).size }.by(-1)
              )

              expect(queued_events).to be == events[1..]
            end
          end

          describe 'with batch_size: less than event count for next 2 events' do
            let(:options) { super().merge(batch_size: 4) }
            let(:expected_events) do
              [
                Spec::AddCommand::Event.new(amount: 2),
                Spec::IncrementCommand::Event.new,
                Spec::IncrementCommand::Event.new,
                Spec::MultiplyCommand::Event.new(amount: 3),
                Spec::AddCommand::Event.new(amount: 2),
                Spec::IncrementCommand::Event.new,
                Spec::IncrementCommand::Event.new,
                Spec::AddCommand::Event.new(amount: 2),
                Spec::IncrementCommand::Event.new,
                Spec::IncrementCommand::Event.new
              ]
            end

            it { expect(process_events).to be true }

            it 'should process the next event and stacked events' do
              process_events

              expect(processed_events).to be == expected_events
            end

            it 'should update the state' do
              process_events

              expect(scene.state.get('value')).to be 6
            end

            it 'should remove the next 2 events from the queue',
              :aggregate_failures \
            do
              expect { process_events }.to(
                change { scene.send(:event_queue).size }.by(-2)
              )

              expect(queued_events).to be == events[2..]
            end
          end

          describe 'with batch_size: equal to event count for next events' do
            let(:options) { super().merge(batch_size: 10) }
            let(:expected_events) do
              [
                Spec::AddCommand::Event.new(amount: 2),
                Spec::IncrementCommand::Event.new,
                Spec::IncrementCommand::Event.new,
                Spec::MultiplyCommand::Event.new(amount: 3),
                Spec::AddCommand::Event.new(amount: 2),
                Spec::IncrementCommand::Event.new,
                Spec::IncrementCommand::Event.new,
                Spec::AddCommand::Event.new(amount: 2),
                Spec::IncrementCommand::Event.new,
                Spec::IncrementCommand::Event.new
              ]
            end

            it { expect(process_events).to be true }

            it 'should process the next event and stacked events' do
              process_events

              expect(processed_events).to be == expected_events
            end

            it 'should update the state' do
              process_events

              expect(scene.state.get('value')).to be 6
            end

            it 'should remove the next 2 events from the queue',
              :aggregate_failures \
            do
              expect { process_events }.to(
                change { scene.send(:event_queue).size }.by(-2)
              )

              expect(queued_events).to be == events[2..]
            end
          end

          describe 'with batch_size: greater than count for next events' do
            let(:options) { super().merge(batch_size: 11) }
            let(:expected_events) do
              [
                Spec::AddCommand::Event.new(amount: 2),
                Spec::IncrementCommand::Event.new,
                Spec::IncrementCommand::Event.new,
                Spec::MultiplyCommand::Event.new(amount: 3),
                Spec::AddCommand::Event.new(amount: 2),
                Spec::IncrementCommand::Event.new,
                Spec::IncrementCommand::Event.new,
                Spec::AddCommand::Event.new(amount: 2),
                Spec::IncrementCommand::Event.new,
                Spec::IncrementCommand::Event.new,
                Spec::AddCommand::Event.new(amount: 4),
                Spec::IncrementCommand::Event.new,
                Spec::IncrementCommand::Event.new,
                Spec::IncrementCommand::Event.new,
                Spec::IncrementCommand::Event.new
              ]
            end

            it { expect(process_events).to be true }

            it 'should process the next event and stacked events' do
              process_events

              expect(processed_events).to be == expected_events
            end

            it 'should update the state' do
              process_events

              expect(scene.state.get('value')).to be 10
            end

            it 'should remove the processed events from the queue',
              :aggregate_failures \
            do
              expect { process_events }.to(
                change { scene.send(:event_queue).size }.by(-3)
              )

              expect(queued_events).to be == []
            end
          end
        end
      end

      describe '#process_next_event' do
        let(:processed_events) { [] }

        define_method :process_event do
          subject.send :process_next_event
        end

        define_method :queued_events do
          queue  = subject.send(:event_queue)
          events = []

          events << queue.pop until queue.empty?

          events
        end

        it 'should define the private method' do
          expect(scene)
            .to respond_to(:process_next_event, true)
            .with(0).arguments
        end

        context 'when there are no queued events' do
          it { expect(process_event).to be 0 }
        end

        context 'when there is one queued event' do
          let(:event) { Ephesus::Core::Message.new }

          before(:example) { subject.enqueue_event(event) }

          context 'when the scene does not handle the event' do
            let(:error_class) do
              Ephesus::Core::Scenes::EventHandling::UnhandledEventError
            end
            let(:error_message) do
              'no event handler found for event ephesus.core'
            end

            it 'should raise an exception' do
              expect { process_event }
                .to raise_error(error_class, error_message)
            end
          end

          wrap_deferred 'when the scene handles the event' do
            let(:event) { Spec::IncrementCommand::Event.new }

            it { expect(process_event).to be 1 }

            it 'should process the event' do
              process_event

              expect(processed_events).to be == [event]
            end

            it 'should update the state' do
              process_event

              expect(scene.state.get('value')).to be 1
            end

            it 'should remove the event from the queue', :aggregate_failures do
              expect { process_event }.to(
                change { scene.send(:event_queue).size }.by(-1)
              )

              expect(queued_events).to be == []
            end
          end
        end

        context 'when there are many queued events' do
          let(:events) { Array.new(3) { Ephesus::Core::Message.new } }

          before(:example) do
            events.each { |event| subject.enqueue_event(event) }
          end

          context 'when the scene does not handle the event' do
            let(:error_class) do
              Ephesus::Core::Scenes::EventHandling::UnhandledEventError
            end
            let(:error_message) do
              'no event handler found for event ephesus.core'
            end

            it 'should raise an exception' do
              expect { process_event }
                .to raise_error(error_class, error_message)
            end
          end

          wrap_deferred 'when the scene handles the event' do
            let(:events) { Array.new(3) { Spec::IncrementCommand::Event.new } }

            it { expect(process_event).to be 1 }

            it 'should process the event' do
              process_event

              expect(processed_events).to be == [events.first]
            end

            it 'should update the state' do
              process_event

              expect(scene.state.get('value')).to be 1
            end

            it 'should remove the event from the queue', :aggregate_failures do
              expect { process_event }.to(
                change { scene.send(:event_queue).size }.by(-1)
              )

              expect(queued_events).to be == events[1..]
            end
          end
        end

        context 'when the handled events push events onto the stack' do
          let(:event) { Spec::MultiplyCommand::Event.new(amount: 3) }
          let(:expected_events) do
            [
              Spec::MultiplyCommand::Event.new(amount: 3),
              Spec::AddCommand::Event.new(amount: 2),
              Spec::IncrementCommand::Event.new,
              Spec::IncrementCommand::Event.new,
              Spec::AddCommand::Event.new(amount: 2),
              Spec::IncrementCommand::Event.new,
              Spec::IncrementCommand::Event.new
            ]
          end

          before(:example) { subject.enqueue_event(event) }

          include_deferred 'when the scene handles the event'

          include_deferred 'when the scene has initial state', value: 2

          it { expect(process_event).to be expected_events.size }

          it 'should process the event and all stacked events' do
            process_event

            expect(processed_events).to be == expected_events
          end

          it 'should update the state' do
            process_event

            expect(scene.state.get('value')).to be 6
          end

          it 'should remove the event from the queue', :aggregate_failures do
            expect { process_event }.to(
              change { scene.send(:event_queue).size }.by(-1)
            )

            expect(queued_events).to be == []
          end
        end
      end

      describe '#processing?' do
        it { expect(subject.processing?).to be false }
      end
    end
  end
end
