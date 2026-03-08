# frozen_string_literal: true

require 'ephesus/core/typing'

RSpec.describe Ephesus::Core::Typing do
  let(:concern)         { Ephesus::Core::Typing } # rubocop:disable RSpec/DescribedClass
  let(:described_class) { Spec::ClassWithType }

  define_method :tools do
    SleepingKingStudios::Tools::Toolbelt.instance
  end

  example_class 'Spec::ClassWithType' do |klass|
    klass.include Ephesus::Core::Typing # rubocop:disable RSpec/DescribedClass
  end

  describe '::EXCLUSIONS' do
    let(:expected) do
      %w[
        action
        command
        event
        notification
      ]
    end

    include_examples 'should define immutable constant',
      :EXCLUSIONS,
      -> { be == expected }
  end

  describe '::FORMAT' do
    let(:format) { described_class::FORMAT }

    include_examples 'should define immutable constant',
      :FORMAT,
      -> { an_instance_of(Regexp) }

    describe 'with an empty String' do
      it { expect(format).not_to match '' }
    end

    describe 'with a lowercase String' do
      it { expect(format).to match 'abc' }
    end

    describe 'with a lowercase String with underscores' do
      it { expect(format).to match 'abc_def' }
    end

    describe 'with a String with numbers' do
      it { expect(format).not_to match 'abc1' }
    end

    describe 'with a String with uppercase letters' do
      it { expect(format).not_to match 'Abc' }
    end

    describe 'with a String with symbols' do
      it { expect(format).not_to match 'abc?' }
    end

    describe 'with a period-separated string' do
      it { expect(format).to match 'abc.def.ghi' }
    end

    describe 'with a colon-separated string' do
      it { expect(format).not_to match 'abc:def:ghi' }
    end
  end

  describe '.default_type_for' do
    let(:default_type) { concern.default_type_for(described_class) }

    it { expect(concern).to respond_to(:default_type_for).with(1).argument }

    describe 'with a class' do
      let(:expected) { 'spec.class_with_type' }

      it { expect(default_type).to be == expected }
    end

    describe 'with an anonymous class' do
      let(:described_class) { Class.new }
      let(:expected)        { nil }

      it { expect(default_type).to be == expected }
    end

    describe 'with an anonymous class with named parent' do
      let(:described_class) { Class.new(super()) }
      let(:expected)        { 'spec.class_with_type' }

      it { expect(default_type).to be == expected }
    end

    describe 'with a data class' do
      let(:described_class) { Spec::DataClass }
      let(:expected)        { 'spec.data_class' }

      example_constant 'Spec::DataClass' do
        Data.define
      end

      it { expect(default_type).to be == expected }
    end

    describe 'with an anonymous data class' do
      let(:described_class) { Data.define }
      let(:expected)        { nil }

      it { expect(default_type).to be == expected }
    end

    describe 'with a class with segment ending in "action"' do
      let(:described_class) { Spec::CustomAction }
      let(:expected)        { 'spec.custom' }

      example_class 'Spec::CustomAction'

      it { expect(default_type).to be == expected }
    end

    describe 'with a class with segment ending in "command"' do
      let(:described_class) { Spec::CustomCommand }
      let(:expected)        { 'spec.custom' }

      example_class 'Spec::CustomCommand'

      it { expect(default_type).to be == expected }
    end

    describe 'with a class with segment ending in "event"' do
      let(:described_class) { Spec::CustomEvent }
      let(:expected)        { 'spec.custom' }

      example_class 'Spec::CustomEvent'

      it { expect(default_type).to be == expected }
    end

    describe 'with a class with segment ending in "notification"' do
      let(:described_class) { Spec::CustomNotification }
      let(:expected)        { 'spec.custom' }

      example_class 'Spec::CustomNotification'

      it { expect(default_type).to be == expected }
    end

    describe 'with a class containing an excluded term' do
      let(:described_class) { Spec::EventData }
      let(:expected)        { 'spec.event_data' }

      example_class 'Spec::EventData'

      it { expect(default_type).to be == expected }
    end

    describe 'with a class with an multiple segments ending in terms' do
      let(:described_class) { Spec::DoSomethingCommand::SuccessEvent }
      let(:expected)        { 'spec.do_something.success' }

      example_class 'Spec::DoSomethingCommand::SuccessEvent'

      it { expect(default_type).to be == expected }
    end
  end

  describe '.type' do
    let(:expected) { 'spec.class_with_type' }

    include_examples 'should define class reader', :type, -> { expected }

    context 'when the class defines a ::TYPE' do
      let(:expected) { 'spec.type_from_constant' }

      before(:example) { described_class.const_set(:TYPE, expected) }

      it { expect(described_class.type).to be == expected }
    end

    context 'when the parent class defines a ::TYPE' do
      let(:parent_class)    { Spec::ClassWithType }
      let(:described_class) { Spec::SubclassWithType }
      let(:expected)        { 'spec.type_from_constant' }

      example_class 'Spec::SubclassWithType', 'Spec::ClassWithType'

      before(:example) { parent_class.const_set(:TYPE, expected) }

      it { expect(described_class.type).to be == expected }
    end

    context 'when the class is an anonymous class' do
      let(:described_class) { Class.new.include(concern) }

      it { expect(described_class.type).to be nil }

      context 'when the class defines a ::TYPE' do
        let(:expected) { 'spec.type_from_constant' }

        before(:example) { described_class.const_set(:TYPE, expected) }

        it { expect(described_class.type).to be == expected }
      end
    end

    context 'when the class name has excluded terms' do
      let(:described_class) { Spec::DoSomethingCommand::SuccessEvent }
      let(:expected)        { 'spec.do_something.success' }

      example_class 'Spec::DoSomethingCommand::SuccessEvent' do |klass|
        klass.include Ephesus::Core::Typing # rubocop:disable RSpec/DescribedClass
      end

      it { expect(described_class.type).to be == expected }

      context 'when the class defines a ::TYPE' do
        let(:expected) { 'spec.type_from_constant' }

        before(:example) { described_class.const_set(:TYPE, expected) }

        it { expect(described_class.type).to be == expected }
      end
    end
  end

  describe '.validate_type' do
    let(:as) { 'type' }

    it 'should define the method' do
      expect(concern)
        .to respond_to(:validate_type)
        .with(1).argument
        .and_keywords(:as)
    end

    describe 'with nil' do
      let(:error_message) do
        tools.assertions.error_message_for(:presence, as:)
      end

      it 'should raise an exception' do
        expect { concern.validate_type(nil) }
          .to raise_error ArgumentError, error_message
      end

      describe 'with as: value' do
        let(:as) { 'event_type' }

        it 'should raise an exception' do
          expect { concern.validate_type(nil, as:) }
            .to raise_error ArgumentError, error_message
        end
      end
    end

    describe 'with an Object' do
      let(:error_message) do
        tools.assertions.error_message_for(:name, as:)
      end

      it 'should raise an exception' do
        expect { concern.validate_type(Object.new.freeze) }
          .to raise_error ArgumentError, error_message
      end

      describe 'with as: value' do
        let(:as) { 'event_type' }

        it 'should raise an exception' do
          expect { concern.validate_type(Object.new.freeze, as:) }
            .to raise_error ArgumentError, error_message
        end
      end
    end

    describe 'with an empty String' do
      let(:error_message) do
        tools.assertions.error_message_for(:presence, as:)
      end

      it 'should raise an exception' do
        expect { concern.validate_type('') }
          .to raise_error ArgumentError, error_message
      end

      describe 'with as: value' do
        let(:as) { 'event_type' }

        it 'should raise an exception' do
          expect { concern.validate_type('', as:) }
            .to raise_error ArgumentError, error_message
        end
      end
    end

    describe 'with an empty Symbol' do
      let(:error_message) do
        tools.assertions.error_message_for(:presence, as:)
      end

      it 'should raise an exception' do
        expect { concern.validate_type(:'') }
          .to raise_error ArgumentError, error_message
      end

      describe 'with as: value' do
        let(:as) { 'event_type' }

        it 'should raise an exception' do
          expect { concern.validate_type(:'', as:) }
            .to raise_error ArgumentError, error_message
        end
      end
    end

    describe 'with an invalid String' do
      let(:error_message) do
        "#{as} must be a lowercase underscored string separated by periods"
      end

      it 'should raise an exception' do
        expect { concern.validate_type('InvalidFormat') }
          .to raise_error ArgumentError, error_message
      end

      describe 'with as: value' do
        let(:as) { 'event_type' }

        it 'should raise an exception' do
          expect { concern.validate_type('InvalidFormat', as:) }
            .to raise_error ArgumentError, error_message
        end
      end
    end

    describe 'with an invalid Symbol' do
      let(:error_message) do
        "#{as} must be a lowercase underscored string separated by periods"
      end

      it 'should raise an exception' do
        expect { concern.validate_type(:'invalid-format') }
          .to raise_error ArgumentError, error_message
      end

      describe 'with as: value' do
        let(:as) { 'event_type' }

        it 'should raise an exception' do
          expect { concern.validate_type(:'invalid-format', as:) }
            .to raise_error ArgumentError, error_message
        end
      end
    end

    describe 'with a valid String' do
      let(:type) { 'spec.custom_type' }

      it { expect(concern.validate_type(type)).to be == type }
    end

    describe 'with a valid Symbol' do
      let(:type) { :'spec.custom_type' }

      it { expect(concern.validate_type(type)).to be == type.to_s }
    end
  end
end
