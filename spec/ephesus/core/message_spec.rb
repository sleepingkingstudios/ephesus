# frozen_string_literal: true

require 'ephesus/core/message'

RSpec.describe Ephesus::Core::Message do
  subject(:event) { described_class.new }

  deferred_context 'with a custom event class' \
  do |class_name = 'Spec::CustomEvent'|
    subject(:event) { described_class.new(custom_property: 'custom value') }

    let(:described_class) { Object.const_get(class_name) }

    example_constant(class_name) do
      Ephesus::Core::Message.define(:custom_property) # rubocop:disable RSpec/DescribedClass
    end
  end

  describe '.define' do
    let(:concern)    { SleepingKingStudios::Tools::Toolbox::HeritableData }
    let(:symbols)    { [] }
    let(:methods)    { nil }
    let(:options)    { {} }
    let(:subclass)   { described_class.define(*symbols, **options, &methods) }
    let(:instance)   { subclass.new(**attributes) }
    let(:attributes) { {} }

    it 'should define the class method' do
      expect(described_class)
        .to respond_to(:define)
        .with_unlimited_arguments
        .and_keywords(:type)
        .and_a_block
    end

    it { expect(subclass).to be_a(Class) }

    it { expect(subclass.superclass).to be Data }

    it { expect(subclass).to be < concern }

    it { expect(subclass.const_defined?(:TYPE)).to be false }

    it { expect(subclass.members).to be == [] }

    it { expect(subclass.type).to be nil }

    describe 'with a block' do
      let(:methods) do
        lambda do
          def loud_type = type&.upcase
        end
      end

      it { expect(instance).to respond_to(:loud_type).with(0).arguments }

      it { expect(instance.loud_type).to be nil }
    end

    describe 'with symbols' do
      let(:symbols) { %i[details] }

      it { expect(subclass.members).to be == %i[details] }
    end

    describe 'with type: nil' do
      let(:options) { super().merge(type: nil) }

      it { expect(subclass.const_defined?(:TYPE)).to be false }

      it { expect(subclass.type).to be nil }
    end

    describe 'with type: an invalid value' do
      let(:options) { super().merge(type: 'InvalidType') }
      let(:error_message) do
        'type must be a lowercase underscored string separated by periods'
      end

      it 'should raise an exception' do
        expect { described_class.define(*symbols, **options, &methods) }
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with type: a valid value' do
      let(:options) { super().merge(type: 'spec.example_type') }

      it { expect(subclass::TYPE).to be == 'spec.example_type' }

      it { expect(subclass.type).to be == 'spec.example_type' }
    end

    wrap_deferred 'with a custom event class' do
      let(:attributes) { super().merge(custom_property: 'custom value') }

      it { expect(subclass).to be_a(Class) }

      it { expect(subclass.superclass).to be Data }

      it { expect(subclass).to be < concern }

      it { expect(subclass.const_defined?(:TYPE)).to be false }

      it { expect(subclass.members).to be == %i[custom_property] }

      it { expect(subclass.type).to be nil }

      describe 'with a block' do
        let(:methods) do
          lambda do
            def loud_type = type&.upcase
          end
        end

        it { expect(instance).to respond_to(:loud_type).with(0).arguments }

        it { expect(instance.loud_type).to be nil }
      end

      describe 'with symbols' do
        let(:symbols) { %i[details] }

        it { expect(subclass.members).to be == %i[custom_property details] }
      end

      describe 'with type: value' do
        let(:options) { super().merge(type: 'spec.example_type') }

        it { expect(subclass::TYPE).to be == 'spec.example_type' }

        it { expect(subclass.type).to be == 'spec.example_type' }
      end
    end
  end

  describe '.type' do
    let(:expected) { 'ephesus.core' }

    include_examples 'should define class reader', :type, -> { expected }

    wrap_deferred 'with a custom event class' do
      it { expect(described_class.type).to be == 'spec.custom' }

      context 'when the class defines a ::TYPE' do
        let(:expected) { 'spec.type_from_constant' }

        before(:example) { described_class.const_set(:TYPE, expected) }

        it { expect(described_class.type).to be == expected }
      end
    end

    context 'with a custom event class with excluded terms' do
      let(:expected) { 'spec.do_something.success' }

      include_deferred 'with a custom event class',
        'Spec::DoSomethingCommand::SuccessEvent'

      it { expect(described_class.type).to be == expected }
    end
  end

  describe '#[]' do
    let(:error_message) do
      "member not found: #{property_name.inspect}"
    end

    it { expect(event).to respond_to(:[]).with(1).argument }

    describe 'with nil' do
      let(:property_name) { nil }

      it 'should raise an exception' do
        expect { event[property_name] }
          .to raise_error NoMethodError, error_message
      end
    end

    describe 'with an Object' do
      let(:property_name) { Object.new.freeze }

      it 'should raise an exception' do
        expect { event[property_name] }
          .to raise_error NoMethodError, error_message
      end
    end

    describe 'with an empty String' do
      let(:property_name) { '' }

      it 'should raise an exception' do
        expect { event[property_name] }
          .to raise_error NoMethodError, error_message
      end
    end

    describe 'with an empty Symbol' do
      let(:property_name) { :'' }

      it 'should raise an exception' do
        expect { event[property_name] }
          .to raise_error NoMethodError, error_message
      end
    end

    describe 'with an invalid String' do
      let(:property_name) { 'invalid_property' }

      it 'should raise an exception' do
        expect { event[property_name] }
          .to raise_error NoMethodError, error_message
      end
    end

    describe 'with an invalid Symbol' do
      let(:property_name) { :invalid_property }

      it 'should raise an exception' do
        expect { event[property_name] }
          .to raise_error NoMethodError, error_message
      end
    end

    describe 'with the name of a non-member method' do
      let(:property_name) { :object_id }

      it 'should raise an exception' do
        expect { event[property_name] }
          .to raise_error NoMethodError, error_message
      end
    end

    wrap_deferred 'with a custom event class' do
      describe 'with an invalid String' do
        let(:property_name) { 'invalid_property' }

        it 'should raise an exception' do
          expect { event[property_name] }
            .to raise_error NoMethodError, error_message
        end
      end

      describe 'with an invalid Symbol' do
        let(:property_name) { :invalid_property }

        it 'should raise an exception' do
          expect { event[property_name] }
            .to raise_error NoMethodError, error_message
        end
      end

      describe 'with a valid String' do
        let(:property_name) { 'custom_property' }
        let(:expected)      { event.send(property_name) }

        it { expect(event[property_name]).to be == expected }
      end

      describe 'with a valid Symbol' do
        let(:property_name) { :custom_property }
        let(:expected)      { event.send(property_name) }

        it { expect(event[property_name]).to be == expected }
      end
    end
  end

  describe '#type' do
    let(:expected) { 'ephesus.core' }

    include_examples 'should define reader', :type, -> { expected }

    wrap_deferred 'with a custom event class' do
      it { expect(event.type).to be == 'spec.custom' }

      context 'when the class defines a ::TYPE' do
        let(:expected) { 'spec.type_from_constant' }

        before(:example) { described_class.const_set(:TYPE, expected) }

        it { expect(event.type).to be == expected }
      end
    end

    context 'with a custom event class with excluded terms' do
      let(:expected) { 'spec.do_something.success' }

      include_deferred 'with a custom event class',
        'Spec::DoSomethingCommand::SuccessEvent'

      it { expect(event.type).to be == expected }
    end
  end
end
