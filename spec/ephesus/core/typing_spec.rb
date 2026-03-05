# frozen_string_literal: true

require 'ephesus/core/typing'

RSpec.describe Ephesus::Core::Typing do
  let(:concern)         { Ephesus::Core::Typing } # rubocop:disable RSpec/DescribedClass
  let(:described_class) { Spec::ClassWithType }

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
end
