# frozen_string_literal: true

require 'ephesus/core/command'

RSpec.describe Ephesus::Core::Command do
  subject(:command) { described_class.new }

  let(:event) { Ephesus::Core::Event.new }
  let(:state) { Ephesus::Core::State.new({}) }

  deferred_context 'with a custom command class' do
    let(:described_class) { Spec::CustomCommand }
    let(:implementation)  { defined?(super()) ? super() : nil }

    example_class 'Spec::CustomCommand', Ephesus::Core::Command do |klass| # rubocop:disable RSpec/DescribedClass
      next if implementation.nil?

      klass.define_method(:process, &implementation)
    end
  end

  describe '.type' do
    let(:expected) { 'ephesus.core' }

    include_examples 'should define class reader', :type, -> { expected }

    wrap_deferred 'with a custom command class' do
      it { expect(described_class.type).to be == 'spec.custom' }

      context 'when the class defines a ::TYPE' do
        let(:expected) { 'spec.type_from_constant' }

        before(:example) { described_class.const_set(:TYPE, expected) }

        it { expect(described_class.type).to be == expected }
      end
    end
  end

  describe '#call' do
    let(:expected_error) do
      Cuprum::Errors::CommandNotImplemented.new(command:)
    end

    it 'should define the method' do
      expect(command)
        .to be_callable
        .with(0).arguments
        .and_keywords(:event, :state)
    end

    it 'should return a failing result' do
      expect(command.call(event:, state:))
        .to be_a_failing_result
        .with_error(expected_error)
    end

    wrap_deferred 'with a custom command class' do
      let(:implementation) { ->(**) { success } }
      let(:expected_value) { state }

      it 'should return a passing result with the state' do
        expect(command.call(event:, state:))
          .to be_a_passing_result
          .with_value(expected_value)
      end

      context 'when the command updates the state' do
        let(:implementation) do
          lambda do |**|
            @state = state.set('secret', 12_345)

            success
          end
        end
        let(:expected_value) { state.set('secret', 12_345) }

        it 'should return a passing result with the updated state' do
          expect(command.call(event:, state:))
            .to be_a_passing_result
            .with_value(expected_value)
        end
      end

      context 'when the command returns side effects' do
        let(:implementation) do
          lambda do |**|
            side_effects << [:side_effect, 'do something']

            success
          end
        end
        let(:expected_value) { [state, [:side_effect, 'do something']] }

        it 'should return a passing result with the side effects' do
          expect(command.call(event:, state:))
            .to be_a_passing_result
            .with_value(expected_value)
        end
      end
    end
  end

  describe '#event' do
    include_examples 'should define reader', :event

    context 'when the command has been called' do
      before(:example) { command.call(event:, state:) }

      it { expect(command.event).to be == event }
    end
  end

  describe '#notify' do
    let(:error_message) do
      "uninitialized constant #{described_class.name}::Notification"
    end

    it 'should define the private method' do
      expect(command)
        .to respond_to(:notify, true)
        .with(0..1).arguments
        .and_any_keywords
    end

    it 'should raise an exception' do
      expect { command.send(:notify) }
        .to raise_error NameError, error_message
    end

    describe 'with a notification name' do
      let(:error_message) do
        "uninitialized constant #{described_class.name}::FailureNotification"
      end

      it 'should raise an exception' do
        expect { command.send(:notify, :failure) }
          .to raise_error NameError, error_message
      end
    end

    wrap_deferred 'with a custom command class' do
      let(:implementation) do
        ->(**) { notify(message: 'Ok!') }
      end
      let(:error_message) do
        "uninitialized constant #{described_class.name}::Notification"
      end

      it 'should raise an exception' do
        expect { command.call(event:, state:) }
          .to raise_error NameError, error_message
      end

      context 'when the command class defines the notification' do
        let(:expected) do
          [
            [
              :notify,
              described_class::Notification.new(message: 'Ok!')
            ]
          ]
        end

        before(:example) do
          described_class.const_set(:Notification, Data.define(:message))
        end

        it 'should add the notification to side effects' do
          command.call(event:, state:)

          expect(command.side_effects).to be == expected
        end
      end

      describe 'with a notification name' do
        let(:implementation) do
          ->(**) { notify(:failure, message: 'Oh no!') }
        end
        let(:error_message) do
          "uninitialized constant #{described_class.name}::FailureNotification"
        end

        it 'should raise an exception' do
          expect { command.call(event:, state:) }
            .to raise_error NameError, error_message
        end

        context 'when the command class defines the notification' do
          let(:expected) do
            [
              [
                :notify,
                described_class::FailureNotification.new(message: 'Oh no!')
              ]
            ]
          end

          before(:example) do
            described_class.const_set(
              :FailureNotification,
              Data.define(:message)
            )
          end

          it 'should add the notification to side effects' do
            command.call(event:, state:)

            expect(command.side_effects).to be == expected
          end
        end
      end
    end
  end

  describe '#side_effects' do
    include_examples 'should define reader', :side_effects

    context 'when the command has been called' do
      before(:example) { command.call(event:, state:) }

      it { expect(command.side_effects).to be == [] }
    end
  end

  describe '#state' do
    include_examples 'should define reader', :state

    context 'when the command has been called' do
      before(:example) { command.call(event:, state:) }

      it { expect(command.state).to be == state }
    end
  end
end
