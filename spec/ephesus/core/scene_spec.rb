# frozen_string_literal: true

require 'ephesus/core/event'
require 'ephesus/core/scene'

RSpec.describe Ephesus::Core::Scene do
  subject(:scene) { described_class.new(**constructor_options) }

  deferred_context 'with a scene subclass' do
    let(:described_class) { Spec::CustomScene }

    example_class 'Spec::CustomScene', Ephesus::Core::Scene # rubocop:disable RSpec/DescribedClass
  end

  deferred_context 'when the scene handles events' do
    example_class 'Spec::Commands::Pop',  Ephesus::Core::Command
    example_class 'Spec::Commands::Pull', Ephesus::Core::Command
    example_class 'Spec::Commands::Push', Ephesus::Core::Command

    before(:example) do
      Spec::CustomScene.handle_event('spec.events.pop', Spec::Commands::Pop)

      Spec::CustomScene.handle_event(Spec::Commands::Pull)
      Spec::CustomScene.handle_event(Spec::Commands::Push)
    end
  end

  let(:constructor_options) { {} }

  define_method :tools do
    SleepingKingStudios::Tools::Toolbelt.instance
  end

  describe '::AbstractClassError' do
    include_examples 'should define constant',
      :AbstractClassError,
      -> { be_a(Class).and be < StandardError }
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

  describe '.abstract?' do
    it { expect(described_class).to respond_to(:abstract?).with(0).arguments }

    it { expect(described_class.abstract?).to be true }

    wrap_deferred 'with a scene subclass' do
      it { expect(described_class.abstract?).to be false }
    end
  end

  describe '.handle_event' do
    let(:command_class) { Spec::CustomCommand }
    let(:error_message) do
      "unable to add event handler for abstract class #{described_class.name}"
    end

    example_class 'Spec::CustomCommand', Ephesus::Core::Command

    it 'should define the class method' do
      expect(described_class).to respond_to(:handle_event).with(1..2).arguments
    end

    it 'should raise an exception' do
      expect { described_class.handle_event(command_class) }
        .to raise_error described_class::AbstractClassError, error_message
    end

    wrap_deferred 'with a scene subclass' do
      describe 'with command_class: nil' do
        let(:error_message) do
          tools.assertions.error_message_for(:class, as: 'command_class')
        end

        it 'should raise an exception' do
          expect { described_class.handle_event(nil) }
            .to raise_error ArgumentError, error_message
        end
      end

      describe 'with command_class: an Object' do
        let(:error_message) do
          tools.assertions.error_message_for(:class, as: 'command_class')
        end

        it 'should raise an exception' do
          expect { described_class.handle_event(Object.new.freeze) }
            .to raise_error ArgumentError, error_message
        end
      end

      describe 'with command_class: a Class' do
        let(:error_message) do
          tools.assertions.error_message_for(
            :inherit_from,
            as:       'command_class',
            expected: Ephesus::Core::Command
          )
        end

        it 'should raise an exception' do
          expect { described_class.handle_event(Class.new) }
            .to raise_error ArgumentError, error_message
        end
      end

      describe 'with command_class: a Command subclass' do
        it 'should register the event handler' do
          described_class.handle_event(command_class)

          expect(described_class.handled_events[command_class.type])
            .to be command_class
        end
      end

      describe 'with event_type: nil' do
        let(:error_message) do
          tools.assertions.error_message_for(:presence, as: 'event_type')
        end

        it 'should raise an exception' do
          expect { described_class.handle_event(nil, command_class) }
            .to raise_error ArgumentError, error_message
        end
      end

      describe 'with event_type: an Object' do
        let(:event_type) { Object.new.freeze }
        let(:error_message) do
          tools.assertions.error_message_for(:name, as: 'event_type')
        end

        it 'should raise an exception' do
          expect { described_class.handle_event(event_type, command_class) }
            .to raise_error ArgumentError, error_message
        end
      end

      describe 'with event_type: an empty String' do
        let(:error_message) do
          tools.assertions.error_message_for(:presence, as: 'event_type')
        end

        it 'should raise an exception' do
          expect { described_class.handle_event('', command_class) }
            .to raise_error ArgumentError, error_message
        end
      end

      describe 'with event_type: an empty Symbol' do
        let(:error_message) do
          tools.assertions.error_message_for(:presence, as: 'event_type')
        end

        it 'should raise an exception' do
          expect { described_class.handle_event(:'', command_class) }
            .to raise_error ArgumentError, error_message
        end
      end

      describe 'with event_type: an invalid String' do
        let(:event_type) { 'InvalidFormat' }
        let(:error_message) do
          'event_type must be a lowercase underscored string separated by ' \
            'periods'
        end

        it 'should raise an exception' do
          expect { described_class.handle_event(event_type, command_class) }
            .to raise_error ArgumentError, error_message
        end
      end

      describe 'with event_type: an invalid Symbol' do
        let(:event_type) { :InvalidFormat }
        let(:error_message) do
          'event_type must be a lowercase underscored string separated by ' \
            'periods'
        end

        it 'should raise an exception' do
          expect { described_class.handle_event(event_type, command_class) }
            .to raise_error ArgumentError, error_message
        end
      end

      describe 'with event_type: value and command_class: nil' do
        let(:event_type) { 'spec.events.custom' }
        let(:error_message) do
          tools.assertions.error_message_for(:class, as: 'command_class')
        end

        it 'should raise an exception' do
          expect { described_class.handle_event(event_type, nil) }
            .to raise_error ArgumentError, error_message
        end
      end

      describe 'with event_type: value and command_class: an Object' do
        let(:event_type)    { 'spec.events.custom' }
        let(:command_class) { Object.new.freeze }
        let(:error_message) do
          tools.assertions.error_message_for(:class, as: 'command_class')
        end

        it 'should raise an exception' do
          expect { described_class.handle_event(event_type, command_class) }
            .to raise_error ArgumentError, error_message
        end
      end

      describe 'with event_type: value and command_class: a Class' do
        let(:event_type)    { 'spec.events.custom' }
        let(:command_class) { Class.new.freeze }
        let(:error_message) do
          tools.assertions.error_message_for(
            :inherit_from,
            as:       'command_class',
            expected: Ephesus::Core::Command
          )
        end

        it 'should raise an exception' do
          expect { described_class.handle_event(event_type, command_class) }
            .to raise_error ArgumentError, error_message
        end
      end

      describe 'with event_type: value and command_class: a Command subclass' do
        let(:event_type) { 'spec.events.custom' }

        it 'should register the event handler' do
          described_class.handle_event(event_type, command_class)

          expect(described_class.handled_events[event_type])
            .to be command_class
        end
      end
    end
  end

  describe '.handled_events' do
    include_examples 'should define class reader', :handled_events, {}

    wrap_deferred 'with a scene subclass' do
      it { expect(described_class.handled_events).to be == {} }

      wrap_deferred 'when the scene handles events' do
        let(:expected) do
          {
            'spec.commands.pull' => Spec::Commands::Pull,
            'spec.commands.push' => Spec::Commands::Push,
            'spec.events.pop'    => Spec::Commands::Pop
          }
        end

        it { expect(described_class.handled_events).to be == expected }
      end

      describe 'with a subclass of the scene subclass' do
        let(:parent_class)    { Spec::CustomScene }
        let(:described_class) { Spec::SceneSubclass }

        example_class 'Spec::SceneSubclass', 'Spec::CustomScene'

        it { expect(described_class.handled_events).to be == {} }

        wrap_deferred 'when the scene handles events' do
          let(:expected) do
            {
              'spec.commands.pull' => Spec::Commands::Pull,
              'spec.commands.push' => Spec::Commands::Push,
              'spec.events.pop'    => Spec::Commands::Pop
            }
          end

          it { expect(described_class.handled_events).to be == expected }
        end

        context 'when the subclass handles events' do
          let(:expected) do
            {
              'spec.balloons.inflate' => Spec::Balloons::Inflate,
              'spec.events.pop'       => Spec::Balloons::Pop
            }
          end

          example_class 'Spec::Balloons::Inflate', Ephesus::Core::Command
          example_class 'Spec::Balloons::Pop',     Ephesus::Core::Command

          before(:example) do
            Spec::SceneSubclass
              .handle_event('spec.events.pop', Spec::Balloons::Pop)

            Spec::SceneSubclass.handle_event Spec::Balloons::Inflate
          end

          it { expect(described_class.handled_events).to be == expected }
        end

        context 'when the scene and subclass handle events' do
          let(:expected) do
            {
              'spec.balloons.inflate' => Spec::Balloons::Inflate,
              'spec.commands.pull'    => Spec::Commands::Pull,
              'spec.commands.push'    => Spec::Commands::Push,
              'spec.events.pop'       => Spec::Balloons::Pop
            }
          end

          example_class 'Spec::Balloons::Inflate', Ephesus::Core::Command
          example_class 'Spec::Balloons::Pop',     Ephesus::Core::Command

          before(:example) do
            Spec::SceneSubclass
              .handle_event('spec.events.pop', Spec::Balloons::Pop)

            Spec::SceneSubclass.handle_event Spec::Balloons::Inflate
          end

          include_deferred 'when the scene handles events'

          it { expect(described_class.handled_events).to be == expected }
        end
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

  describe '#enqueue_event' do
    let(:event) { Ephesus::Core::Event.new }

    define_method :enqueued_events do
      scene.send(:event_queue)
    end

    it { expect(scene).to respond_to(:enqueue_event).with(1).argument }

    it { expect(scene).to have_aliased_method(:enqueue_event).as(:enqueue) }

    it 'should push the event onto the events queue' do
      expect { scene.enqueue_event(event) }.to(
        change { enqueued_events }.to(
          satisfy { |queue| queue.size == 1 && queue.last == event }
        )
      )
    end
  end

  describe '#event_queue' do
    include_examples 'should define private reader', :event_queue, []
  end

  describe '#event_stack' do
    include_examples 'should define private reader', :event_stack, []
  end

  describe '#handle_event' do
    let(:event) { Spec::CustomEvent.new(message: 'Ad astra!') }

    example_constant 'Spec::CustomEvent' do
      Ephesus::Core::Event.define(:message)
    end

    it { expect(scene).to respond_to(:handle_event, true).with(1).argument }

    describe 'with an unhandled event' do
      let(:error_message) do
        event_data = event.to_h.inspect

        "no event handler found for event #{event.type} (#{event_data})"
      end

      it 'should raise an exception' do
        expect { scene.send(:handle_event, event) }
          .to raise_error described_class::UnhandledEventError, error_message
      end
    end

    wrap_deferred 'with a scene subclass' do
      describe 'with an unhandled event' do
        let(:error_message) do
          event_data = event.to_h.inspect

          "no event handler found for event #{event.type} (#{event_data})"
        end

        it 'should raise an exception' do
          expect { scene.send(:handle_event, event) }
            .to raise_error described_class::UnhandledEventError, error_message
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
          described_class.handle_event(event.type, command_class)

          allow(scene).to receive(:handle_side_effect) do |side_effect, details| # rubocop:disable RSpec/SubjectStub
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

        # rubocop:disable RSpec/NestedGroups
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
                .set('checksum', 0xdeadbeef)

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
                .set('checksum', 0xdeadbeef)

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
                .set('checksum', 0xdeadbeef)

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
                .set('checksum', 0xdeadbeef)

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
        # rubocop:enable RSpec/NestedGroups
      end
    end
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
      let(:side_effect)  { :notify }
      let(:notification) { Ephesus::Core::Event.new }
      let(:observer)     { Spec::Observer.new }

      example_class 'Spec::Observer' do |klass|
        klass.define_method(:notifications) { @notifications ||= [] }

        klass.define_method(:update) { |obj| notifications << obj }
      end

      before(:example) { scene.add_observer(observer) }

      it 'should notify the observers' do
        scene.send(:handle_side_effect, side_effect, notification)

        expect(observer.notifications).to be == [notification]
      end
    end

    describe 'with a :push_event effect' do
      let(:side_effect) { :push_event }
      let(:event) do
        Spec::CustomEvent.new(message: 'Greetings, programs!')
      end

      example_constant 'Spec::CustomEvent' do
        Ephesus::Core::Event.define(:message)
      end

      it 'should push the event to the #event_stack', :aggregate_failures do
        expect { scene.send(:handle_side_effect, side_effect, event) }.to(
          change { scene.send(:event_stack).count }.by(1)
        )

        expect(scene.send(:event_stack).last).to be == event
      end

      context 'when the scene has many stacked events' do
        before(:example) do
          3.times { scene.send(:event_stack).push(Ephesus::Core::Event.new) }
        end

        it 'should push the event to the #event_stack', :aggregate_failures do
          expect { scene.send(:handle_side_effect, side_effect, event) }.to(
            change { scene.send(:event_stack).count }.by(1)
          )

          expect(scene.send(:event_stack).last).to be == event
        end
      end
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
end
