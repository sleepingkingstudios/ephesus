# frozen_string_literal: true

require 'ephesus/core/state'

RSpec.describe Ephesus::Core::State do
  subject(:state) { described_class.new(initial_state) }

  deferred_context 'when initialized with an initial state' do
    let(:initial_state) do
      {
        'path'   => { 'to' => { 'scoped_value' => :value } },
        'secret' => 12_345,
        'user'   => Struct.new(:name, :data).new('Alan Bradley', {})
      }
    end
  end

  define_method :tools do
    SleepingKingStudios::Tools::Toolbelt.instance
  end

  let(:initial_state) { {} }

  describe '.new' do
    it { expect(described_class).to be_constructible.with(1).argument }

    describe 'with nil' do
      let(:error_message) do
        tools.assertions.error_message_for(
          :instance_of,
          as:       'initial_state',
          expected: Hash
        )
      end

      it 'should raise an exception' do
        expect { described_class.new(nil) }
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with an Object' do
      let(:error_message) do
        tools.assertions.error_message_for(
          :instance_of,
          as:       'initial_state',
          expected: Hash
        )
      end

      it 'should raise an exception' do
        expect { described_class.new(Object.new.freeze) }
          .to raise_error ArgumentError, error_message
      end
    end
  end

  describe '#fetch' do
    deferred_examples 'should raise a KeyError' do |expected_key = nil|
      let(:error_message) do
        expected = expected_key || path

        "key not found: #{expected.inspect}"
      end

      it 'should raise an exception' do
        expect { state.fetch(path) }
          .to raise_error KeyError, error_message
      end
    end

    deferred_examples 'should return the default value' do
      describe 'with default: block' do
        let(:default_block) do
          ->(key = nil) { "default value: #{key.inspect}" }
        end
        let(:expected) do
          "default value: #{path.to_s.split('.').last.inspect}"
        end

        it { expect(state.fetch(path, &default_block)).to be == expected }
      end

      describe 'with default: value' do
        let(:default_value) { 'default value' }

        it { expect(state.fetch(path, default_value)).to be == default_value }
      end
    end

    it { expect(state).to respond_to(:fetch).with(1..2).arguments.and_a_block }

    describe 'with nil' do
      let(:path) { nil }

      include_deferred 'should raise a KeyError'
    end

    describe 'with an Object' do
      let(:path) { Object.new.freeze }

      include_deferred 'should raise a KeyError'
    end

    describe 'with an empty String' do
      let(:path) { '' }

      include_deferred 'should raise a KeyError'
    end

    describe 'with an empty Symbol' do
      let(:path) { :'' }

      include_deferred 'should raise a KeyError'
    end

    describe 'with an invalid String' do
      let(:path) { 'invalid_key' }

      include_deferred 'should raise a KeyError'

      include_deferred 'should return the default value'
    end

    describe 'with an invalid Symbol' do
      let(:path) { :invalid_key }

      include_deferred 'should raise a KeyError', 'invalid_key'

      include_deferred 'should return the default value'
    end

    wrap_deferred 'when initialized with an initial state' do
      describe 'with an invalid String' do
        let(:path) { 'invalid_key' }

        include_deferred 'should raise a KeyError'

        include_deferred 'should return the default value'
      end

      describe 'with an invalid Symbol' do
        let(:path) { :invalid_key }

        include_deferred 'should raise a KeyError', 'invalid_key'

        include_deferred 'should return the default value'
      end

      describe 'with an invalid scoped String' do
        let(:path) { 'path.to.another_value' }

        include_deferred 'should raise a KeyError', 'another_value'

        include_deferred 'should return the default value'
      end

      describe 'with an invalid property of an object' do
        let(:path)          { 'user.password' }
        let(:error_message) { /undefined method 'password'/ }

        it 'should raise an exception' do
          expect { state.fetch(path) }
            .to raise_error NoMethodError, error_message
        end
      end

      describe 'with a valid String' do
        it { expect(state.fetch('secret')).to be 12_345 }
      end

      describe 'with a valid Symbol' do
        it { expect(state.fetch(:secret)).to be 12_345 }
      end

      describe 'with a valid scoped String' do
        it { expect(state.fetch('path.to.scoped_value')).to be :value }
      end

      describe 'with a valid scoped Symbol' do
        it { expect(state.fetch(:'path.to.scoped_value')).to be :value }
      end

      describe 'with a valid property of an object' do
        it { expect(state.fetch('user.name')).to be == 'Alan Bradley' }
      end
    end
  end

  describe '#get' do
    it { expect(state).to respond_to(:get).with(1).argument }

    describe 'with nil' do
      it { expect(state.get(nil)).to be nil }
    end

    describe 'with an Object' do
      it { expect(state.get(Object.new.freeze)).to be nil }
    end

    describe 'with an empty String' do
      it { expect(state.get('')).to be nil }
    end

    describe 'with an empty Symbol' do
      it { expect(state.get(:'')).to be nil }
    end

    describe 'with an invalid String' do
      it { expect(state.get('invalid_key')).to be nil }
    end

    describe 'with an invalid Symbol' do
      it { expect(state.get(:invalid_key)).to be nil }
    end

    wrap_deferred 'when initialized with an initial state' do
      describe 'with an empty String' do
        it { expect(state.get('')).to be nil }
      end

      describe 'with an empty Symbol' do
        it { expect(state.get(:'')).to be nil }
      end

      describe 'with an invalid String' do
        it { expect(state.get('invalid_key')).to be nil }
      end

      describe 'with an invalid Symbol' do
        it { expect(state.get(:invalid_key)).to be nil }
      end

      describe 'with an invalid scoped String' do
        it { expect(state.get('path.to.another_value')).to be nil }
      end

      describe 'with an invalid scoped Symbol' do
        it { expect(state.get(:'path.to.another_value')).to be nil }
      end

      describe 'with an invalid property of an object' do
        it { expect(state.get('user.password')).to be nil }
      end

      describe 'with a valid String' do
        it { expect(state.get('secret')).to be 12_345 }
      end

      describe 'with a valid Symbol' do
        it { expect(state.get(:secret)).to be 12_345 }
      end

      describe 'with a valid scoped String' do
        it { expect(state.get('path.to.scoped_value')).to be :value }
      end

      describe 'with a valid scoped Symbol' do
        it { expect(state.get(:'path.to.scoped_value')).to be :value }
      end

      describe 'with a valid property of an object' do
        it { expect(state.get('user.name')).to be == 'Alan Bradley' }
      end
    end

    context 'when initialized with an initial state with Symbol keys' do
      let(:initial_state) do
        tools.hsh.convert_keys_to_symbols(super())
      end

      include_deferred 'when initialized with an initial state'

      describe 'with an empty String' do
        it { expect(state.get('')).to be nil }
      end

      describe 'with an empty Symbol' do
        it { expect(state.get(:'')).to be nil }
      end

      describe 'with an invalid String' do
        it { expect(state.get('invalid_key')).to be nil }
      end

      describe 'with an invalid Symbol' do
        it { expect(state.get(:invalid_key)).to be nil }
      end

      describe 'with a valid String' do
        it { expect(state.get('secret')).to be 12_345 }
      end

      describe 'with a valid Symbol' do
        it { expect(state.get(:secret)).to be 12_345 }
      end

      describe 'with a scoped String' do
        it { expect(state.get('path.to.scoped_value')).to be :value }
      end

      describe 'with a scoped Symbol' do
        it { expect(state.get(:'path.to.scoped_value')).to be :value }
      end

      describe 'with a property of an object' do
        it { expect(state.get('user.name')).to be == 'Alan Bradley' }
      end
    end
  end

  describe '#set' do
    deferred_examples 'should update the value' do
      it { expect(state.set(path, value, **options)).to be_a described_class }

      it 'should set the value on the returned state' do
        updated = state.set(path, value, **options)

        expect(updated.get(path)).to be == value
      end
    end

    let(:value)   { :value }
    let(:options) { {} }

    it 'should define the method' do
      expect(state)
        .to respond_to(:set)
        .with(2).arguments
        .and_keywords(:intermediate_path)
    end

    describe 'with path: nil' do
      let(:error_message) do
        tools.assertions.error_message_for(:presence, as: 'path')
      end

      it 'should raise an exception' do
        expect { state.set(nil, value) }
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with path: an Object' do
      let(:error_message) do
        tools.assertions.error_message_for(:name, as: 'path')
      end

      it 'should raise an exception' do
        expect { state.set(Object.new.freeze, value) }
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with path: an empty String' do
      let(:error_message) do
        tools.assertions.error_message_for(:presence, as: 'path')
      end

      it 'should raise an exception' do
        expect { state.set('', value) }
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with path: an empty Symbol' do
      let(:error_message) do
        tools.assertions.error_message_for(:presence, as: 'path')
      end

      it 'should raise an exception' do
        expect { state.set(:'', value) }
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with path: an invalid String' do
      let(:error_message) do
        'path must be a lowercase underscored string separated by periods'
      end

      it 'should raise an exception' do
        expect { state.set('InvalidFormat', value) }
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with path: an invalid Symbol' do
      let(:error_message) do
        'path must be a lowercase underscored string separated by periods'
      end

      it 'should raise an exception' do
        expect { state.set(:'invalid-format', value) }
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with path: a scoped path with missing segments' do
      let(:path)  { 'weapons.swords.longsword' }
      let(:value) { 'zweihänder' }
      let(:error_message) do
        expected = 'weapons'

        "key not found: #{expected.inspect}"
      end

      it 'should raise an exception' do
        expect { state.set(path, value) }
          .to raise_error KeyError, error_message
      end

      describe 'with intermediate_path: true' do
        let(:options) { super().merge(intermediate_path: true) }

        include_deferred 'should update the value'
      end
    end

    describe 'with path: a valid String' do
      let(:path)  { 'checksum' }
      let(:value) { 0xdeadbeef }

      include_deferred 'should update the value'
    end

    describe 'with path: a valid Symbol' do
      let(:path)  { :checksum }
      let(:value) { 0xdeadbeef }

      include_deferred 'should update the value'
    end

    wrap_deferred 'when initialized with an initial state' do
      describe 'with path: an invalid String' do
        let(:error_message) do
          'path must be a lowercase underscored string separated by periods'
        end

        it 'should raise an exception' do
          expect { state.set('InvalidFormat', value) }
            .to raise_error ArgumentError, error_message
        end
      end

      describe 'with path: an invalid Symbol' do
        let(:error_message) do
          'path must be a lowercase underscored string separated by periods'
        end

        it 'should raise an exception' do
          expect { state.set(:'invalid-format', value) }
            .to raise_error ArgumentError, error_message
        end
      end

      describe 'with path: a scoped path with missing segments' do
        let(:path)  { 'weapons.swords.longsword' }
        let(:value) { 'zweihänder' }
        let(:error_message) do
          expected = 'weapons'

          "key not found: #{expected.inspect}"
        end

        it 'should raise an exception' do
          expect { state.set(path, value) }
            .to raise_error KeyError, error_message
        end

        describe 'with intermediate_path: true' do
          let(:options) { super().merge(intermediate_path: true) }

          include_deferred 'should update the value'
        end
      end

      describe 'with path: a partially-valid scoped path' do
        let(:path)  { 'path.from.here.to.there' }
        let(:value) { 'a maze of twisting passages, all alike' }
        let(:error_message) do
          expected = 'from'

          "key not found: #{expected.inspect}"
        end

        it 'should raise an exception' do
          expect { state.set(path, value) }
            .to raise_error KeyError, error_message
        end

        describe 'with intermediate_path: true' do
          let(:options) { super().merge(intermediate_path: true) }

          include_deferred 'should update the value'
        end
      end

      describe 'with path: an invalid property of an object' do
        let(:path)          { 'user.password' }
        let(:value)         { 'l3tm31n' }
        let(:error_message) { /undefined method 'password='/ }

        it 'should raise an exception' do
          expect { state.set(path, value) }
            .to raise_error NoMethodError, error_message
        end
      end

      describe 'with path: a valid String' do
        let(:path)  { 'checksum' }
        let(:value) { 0xdeadbeef }

        include_deferred 'should update the value'
      end

      describe 'with path: a valid Symbol' do
        let(:path)  { :checksum }
        let(:value) { 0xdeadbeef }

        include_deferred 'should update the value'
      end

      describe 'with path: an existing path' do
        let(:path)  { 'secret' }
        let(:value) { '[redacted]' }

        include_deferred 'should update the value'
      end

      describe 'with path: a valid property of an object' do
        let(:path)  { 'user.name' }
        let(:value) { 'Kevin Flynn' }

        include_deferred 'should update the value'
      end

      describe 'with path: a nested property of an object' do
        let(:path)    { 'user.data.role' }
        let(:value)   { 'admin' }
        let(:options) { super().merge(intermediate_path: true) }

        include_deferred 'should update the value'
      end
    end

    describe 'with a subclass of State' do
      let(:described_class) { Spec::CustomState }

      example_class 'Spec::CustomState', Ephesus::Core::State # rubocop:disable RSpec/DescribedClass

      describe 'with path: a valid String' do
        let(:path)  { 'checksum' }
        let(:value) { 0xdeadbeef }

        include_deferred 'should update the value'
      end

      describe 'with path: a valid Symbol' do
        let(:path)  { :checksum }
        let(:value) { 0xdeadbeef }

        include_deferred 'should update the value'
      end
    end
  end
end
