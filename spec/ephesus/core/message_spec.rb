# frozen_string_literal: true

require 'ephesus/core/message'

RSpec.describe Ephesus::Core::Message do
  subject(:message) { described_class.new }

  deferred_context 'with a custom message class' \
  do |class_name = 'Spec::CustomEvent'|
    subject(:message) { described_class.new(custom_property: 'custom value') }

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

    wrap_deferred 'with a custom message class' do
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

    wrap_deferred 'with a custom message class' do
      it { expect(described_class.type).to be == 'spec.custom' }

      context 'when the class defines a ::TYPE' do
        let(:expected) { 'spec.type_from_constant' }

        before(:example) { described_class.const_set(:TYPE, expected) }

        it { expect(described_class.type).to be == expected }
      end
    end

    context 'with a custom message class with excluded terms' do
      let(:expected) { 'spec.do_something.success' }

      include_deferred 'with a custom message class',
        'Spec::DoSomethingCommand::SuccessEvent'

      it { expect(described_class.type).to be == expected }
    end
  end

  describe '#[]' do
    let(:error_message) do
      "member not found: #{property_name.inspect}"
    end

    it { expect(message).to respond_to(:[]).with(1).argument }

    describe 'with nil' do
      let(:property_name) { nil }

      it 'should raise an exception' do
        expect { message[property_name] }
          .to raise_error NoMethodError, error_message
      end
    end

    describe 'with an Object' do
      let(:property_name) { Object.new.freeze }

      it 'should raise an exception' do
        expect { message[property_name] }
          .to raise_error NoMethodError, error_message
      end
    end

    describe 'with an empty String' do
      let(:property_name) { '' }

      it 'should raise an exception' do
        expect { message[property_name] }
          .to raise_error NoMethodError, error_message
      end
    end

    describe 'with an empty Symbol' do
      let(:property_name) { :'' }

      it 'should raise an exception' do
        expect { message[property_name] }
          .to raise_error NoMethodError, error_message
      end
    end

    describe 'with an invalid String' do
      let(:property_name) { 'invalid_property' }

      it 'should raise an exception' do
        expect { message[property_name] }
          .to raise_error NoMethodError, error_message
      end
    end

    describe 'with an invalid Symbol' do
      let(:property_name) { :invalid_property }

      it 'should raise an exception' do
        expect { message[property_name] }
          .to raise_error NoMethodError, error_message
      end
    end

    describe 'with the name of a non-member method' do
      let(:property_name) { :object_id }

      it 'should raise an exception' do
        expect { message[property_name] }
          .to raise_error NoMethodError, error_message
      end
    end

    wrap_deferred 'with a custom message class' do
      describe 'with an invalid String' do
        let(:property_name) { 'invalid_property' }

        it 'should raise an exception' do
          expect { message[property_name] }
            .to raise_error NoMethodError, error_message
        end
      end

      describe 'with an invalid Symbol' do
        let(:property_name) { :invalid_property }

        it 'should raise an exception' do
          expect { message[property_name] }
            .to raise_error NoMethodError, error_message
        end
      end

      describe 'with a valid String' do
        let(:property_name) { 'custom_property' }
        let(:expected)      { message.send(property_name) }

        it { expect(message[property_name]).to be == expected }
      end

      describe 'with a valid Symbol' do
        let(:property_name) { :custom_property }
        let(:expected)      { message.send(property_name) }

        it { expect(message[property_name]).to be == expected }
      end
    end
  end

  describe '#as_json' do
    let(:expected) { { 'type' => message.type } }

    it { expect(message).to respond_to(:as_json).with(0).arguments }

    it { expect(message.as_json).to be == expected }

    wrap_deferred 'with a custom message class' do
      subject(:message) { described_class.new(custom_property:) }

      let(:custom_property) { 'custom value' }
      let(:expected_value)  { custom_property }
      let(:expected) do
        super().merge('custom_property' => expected_value)
      end

      it { expect(message.as_json).to be == expected }

      context 'with a nil value' do
        let(:custom_property) { nil }

        it { expect(message.as_json).to be == expected }
      end

      context 'with a false value' do
        let(:custom_property) { false }

        it { expect(message.as_json).to be == expected }
      end

      context 'with a true value' do
        let(:custom_property) { true }

        it { expect(message.as_json).to be == expected }
      end

      context 'with an integer value' do
        let(:custom_property) { 0 }

        it { expect(message.as_json).to be == expected }
      end

      context 'with a float value' do
        let(:custom_property) { 0.0 }

        it { expect(message.as_json).to be == expected }
      end

      context 'with a String value' do
        let(:custom_property) { 'custom value' }

        it { expect(message.as_json).to be == expected }
      end

      context 'with a Symbol value' do
        let(:custom_property) { :'custom value' }
        let(:expected_value)  { custom_property.to_s }

        it { expect(message.as_json).to be == expected }
      end

      context 'with an Object value' do
        let(:custom_property) { Object.new.freeze }
        let(:expected_value)  { custom_property.to_s }

        it { expect(message.as_json).to be == expected }
      end

      context 'with a value that responds to :as_json' do
        let(:custom_property) { Spec::CustomObject.new }
        let(:expected_value)  { custom_property.as_json }

        example_class 'Spec::CustomObject' do |klass|
          klass.define_method(:as_json) { { 'name' => 'Spec::CustomObject' } }
        end

        it { expect(message.as_json).to be == expected }
      end

      context 'with an Array value' do
        let(:custom_property) { Array.new(3) { Spec::CustomObject.new } }
        let(:expected_value)  { custom_property.map(&:as_json) }

        example_class 'Spec::CustomObject' do |klass|
          klass.define_method(:as_json) { { 'name' => 'Spec::CustomObject' } }
        end

        it { expect(message.as_json).to be == expected }
      end

      context 'with a Hash value with String keys' do
        let(:custom_property) { { 'custom' => Spec::CustomObject.new } }
        let(:expected_value)  { custom_property.transform_values(&:as_json) }

        example_class 'Spec::CustomObject' do |klass|
          klass.define_method(:as_json) { { 'name' => 'Spec::CustomObject' } }
        end

        it { expect(message.as_json).to be == expected }
      end

      context 'with a Hash value with Symbol keys' do
        let(:custom_property) { { custom: Spec::CustomObject.new } }
        let(:expected_value) do
          custom_property
            .transform_keys(&:to_s)
            .transform_values(&:as_json)
        end

        example_class 'Spec::CustomObject' do |klass|
          klass.define_method(:as_json) { { 'name' => 'Spec::CustomObject' } }
        end

        it { expect(message.as_json).to be == expected }
      end
    end
  end

  describe '#inspect' do
    let(:expected) do
      "#<#{described_class.name}>"
    end

    it { expect(message.inspect).to be == expected }

    wrap_deferred 'with a custom message class' do
      let(:expected) do
        "#{super()[...-1]} custom_property=#{message.custom_property.inspect}>"
      end

      it { expect(message.inspect).to be == expected }
    end
  end

  describe '#type' do
    let(:expected) { 'ephesus.core' }

    include_examples 'should define reader', :type, -> { expected }

    wrap_deferred 'with a custom message class' do
      it { expect(message.type).to be == 'spec.custom' }

      context 'when the class defines a ::TYPE' do
        let(:expected) { 'spec.type_from_constant' }

        before(:example) { described_class.const_set(:TYPE, expected) }

        it { expect(message.type).to be == expected }
      end
    end

    context 'with a custom message class with excluded terms' do
      let(:expected) { 'spec.do_something.success' }

      include_deferred 'with a custom message class',
        'Spec::DoSomethingCommand::SuccessEvent'

      it { expect(message.type).to be == expected }
    end
  end
end
