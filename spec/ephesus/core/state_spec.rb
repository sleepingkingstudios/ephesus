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

    describe 'with a lowercase String with dashes' do
      it { expect(format).to match 'abc-def' }
    end

    describe 'with a lowercase String with underscores' do
      it { expect(format).to match 'abc_def' }
    end

    describe 'with a String with leading numbers' do
      it { expect(format).to match '1abc' }
    end

    describe 'with a String with trailing numbers' do
      it { expect(format).to match 'abc1' }
    end

    describe 'with a String with uppercase letters' do
      it { expect(format).not_to match 'Abc' }
    end

    describe 'with a String with symbols' do
      it { expect(format).not_to match 'abc?' }
    end

    describe 'with a period-separated string' do
      it { expect(format).not_to match 'abc.def.ghi' }
    end

    describe 'with a colon-separated string' do
      it { expect(format).not_to match 'abc:def:ghi' }
    end
  end

  describe '.validate_path' do
    let(:as) { 'path' }

    it 'should define the method' do
      expect(described_class)
        .to respond_to(:validate_path)
        .with(1).argument
        .and_unlimited_arguments
        .and_keywords(:as)
    end

    describe 'with nil' do
      let(:error_message) do
        tools.assertions.error_message_for(:presence, as:)
      end

      it 'should raise an exception' do
        expect { described_class.validate_path(nil) }
          .to raise_error ArgumentError, error_message
      end

      describe 'with as: value' do
        let(:as) { 'absolute_path' }

        it 'should raise an exception' do
          expect { described_class.validate_path(nil, as:) }
            .to raise_error ArgumentError, error_message
        end
      end
    end

    describe 'with an Object' do
      let(:error_message) do
        tools.assertions.error_message_for(:name, as:)
      end

      it 'should raise an exception' do
        expect { described_class.validate_path(Object.new.freeze) }
          .to raise_error ArgumentError, error_message
      end

      describe 'with as: value' do
        let(:as) { 'absolute_path' }

        it 'should raise an exception' do
          expect { described_class.validate_path(Object.new.freeze, as:) }
            .to raise_error ArgumentError, error_message
        end
      end
    end

    describe 'with an empty String' do
      let(:error_message) do
        tools.assertions.error_message_for(:presence, as:)
      end

      it 'should raise an exception' do
        expect { described_class.validate_path('') }
          .to raise_error ArgumentError, error_message
      end

      describe 'with as: value' do
        let(:as) { 'event_type' }

        it 'should raise an exception' do
          expect { described_class.validate_path('', as:) }
            .to raise_error ArgumentError, error_message
        end
      end
    end

    describe 'with an empty Symbol' do
      let(:error_message) do
        tools.assertions.error_message_for(:presence, as:)
      end

      it 'should raise an exception' do
        expect { described_class.validate_path(:'') }
          .to raise_error ArgumentError, error_message
      end

      describe 'with as: value' do
        let(:as) { 'absolute_path' }

        it 'should raise an exception' do
          expect { described_class.validate_path(:'', as:) }
            .to raise_error ArgumentError, error_message
        end
      end
    end

    describe 'with an invalid String' do
      let(:error_message) do
        "#{as} must be a String containing only lowercase letters, digits, " \
          'underscores, and dashes'
      end

      it 'should raise an exception' do
        expect { described_class.validate_path('InvalidFormat') }
          .to raise_error ArgumentError, error_message
      end

      describe 'with as: value' do
        let(:as) { 'absolute_path' }

        it 'should raise an exception' do
          expect { described_class.validate_path('InvalidFormat', as:) }
            .to raise_error ArgumentError, error_message
        end
      end
    end

    describe 'with an invalid Symbol' do
      let(:error_message) do
        "#{as} must be a String containing only lowercase letters, digits, " \
          'underscores, and dashes'
      end

      it 'should raise an exception' do
        expect { described_class.validate_path(:InvalidFormat) }
          .to raise_error ArgumentError, error_message
      end

      describe 'with as: value' do
        let(:as) { 'absolute_path' }

        it 'should raise an exception' do
          expect { described_class.validate_path(:InvalidFormat, as:) }
            .to raise_error ArgumentError, error_message
        end
      end
    end

    describe 'with a valid String' do
      let(:path) { 'custom_type' }

      it { expect(described_class.validate_path(path)).to be == [path] }
    end

    describe 'with a valid Symbol' do
      let(:path) { :custom_type }

      it { expect(described_class.validate_path(path)).to be == [path.to_s] }
    end

    describe 'with multiple valid Strings' do
      let(:path) { %w[path to value] }

      it { expect(described_class.validate_path(*path)).to be == path }
    end

    describe 'with multiple valid Symbols' do
      let(:path)     { %i[path to value] }
      let(:expected) { path.map(&:to_s) }

      it { expect(described_class.validate_path(*path)).to be == expected }
    end
  end

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

  describe '#==' do
    describe 'with nil' do
      it { expect(state == nil).to be false } # rubocop:disable Style/NilComparison
    end

    describe 'with an Object' do
      it { expect(state == Object.new.freeze).to be false }
    end

    describe 'with a State with non-matching state' do
      let(:other_state) { { 'checksum' => 0xdeadbeef } }

      it { expect(state == described_class.new(other_state)).to be false }
    end

    describe 'with a State with matching state' do
      it { expect(state == described_class.new({})).to be true }
    end

    wrap_deferred 'when initialized with an initial state' do
      describe 'with a State with empty state' do
        it { expect(state == described_class.new({})).to be false }
      end

      describe 'with a State with non-matching state' do
        let(:other_state) { { 'checksum' => 0xdeadbeef } }

        it { expect(state == described_class.new(other_state)).to be false }
      end

      describe 'with a State with matching state' do
        it { expect(state == described_class.new(initial_state)).to be true }
      end
    end
  end

  describe '#delete' do
    deferred_examples 'should update the value' do
      it { expect(state.delete(*path)).to be_a described_class }

      it 'should clear the value on the returned state', :aggregate_failures do # rubocop:disable RSpec/ExampleLength
        *scope, key = path

        updated = state.delete(*scope, key)
        parent  = scope.empty? ? updated.to_h : updated.get(*scope)

        if parent.is_a?(Hash)
          expect(parent.key?(key.to_s)).to be false
        else
          expect(parent.public_send(key)).to be nil
        end
      end
    end

    it { expect(state).to respond_to(:delete).with_unlimited_arguments }

    describe 'with path: nil' do
      let(:error_message) do
        tools.assertions.error_message_for(:presence, as: 'path')
      end

      it 'should raise an exception' do
        expect { state.delete(nil) }
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with path: an Object' do
      let(:error_message) do
        tools.assertions.error_message_for(:name, as: 'path')
      end

      it 'should raise an exception' do
        expect { state.delete(Object.new.freeze) }
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with path: an empty String' do
      let(:error_message) do
        tools.assertions.error_message_for(:presence, as: 'path')
      end

      it 'should raise an exception' do
        expect { state.delete('') }
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with path: an empty Symbol' do
      let(:error_message) do
        tools.assertions.error_message_for(:presence, as: 'path')
      end

      it 'should raise an exception' do
        expect { state.delete(:'') }
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with path: an invalid String' do
      let(:error_message) do
        'path must be a String containing only lowercase letters, digits, ' \
          'underscores, and dashes'
      end

      it 'should raise an exception' do
        expect { state.delete('InvalidFormat') }
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with path: an invalid Symbol' do
      let(:error_message) do
        'path must be a String containing only lowercase letters, digits, ' \
          'underscores, and dashes'
      end

      it 'should raise an exception' do
        expect { state.delete(:InvalidFormat) }
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with path: a scoped path with missing segments' do
      let(:path)  { %w[weapons swords longsword] }
      let(:value) { 'zweihänder' }
      let(:error_message) do
        expected = 'weapons'

        "key not found: #{expected.inspect}"
      end

      it 'should raise an exception' do
        expect { state.delete(*path) }
          .to raise_error KeyError, error_message
      end
    end

    describe 'with path: a valid String' do
      let(:path) { %w[checksum] }

      include_deferred 'should update the value'
    end

    describe 'with path: a valid Symbol' do
      let(:path) { %i[checksum] }

      include_deferred 'should update the value'
    end

    wrap_deferred 'when initialized with an initial state' do
      describe 'with path: an invalid String' do
        let(:error_message) do
          'path must be a String containing only lowercase letters, digits, ' \
            'underscores, and dashes'
        end

        it 'should raise an exception' do
          expect { state.delete('InvalidFormat') }
            .to raise_error ArgumentError, error_message
        end
      end

      describe 'with path: an invalid Symbol' do
        let(:error_message) do
          'path must be a String containing only lowercase letters, digits, ' \
            'underscores, and dashes'
        end

        it 'should raise an exception' do
          expect { state.delete(:InvalidFormat) }
            .to raise_error ArgumentError, error_message
        end
      end

      describe 'with path: a scoped path with missing segments' do
        let(:path)  { %w[weapons swords longsword] }
        let(:value) { 'zweihänder' }
        let(:error_message) do
          expected = 'weapons'

          "key not found: #{expected.inspect}"
        end

        it 'should raise an exception' do
          expect { state.delete(*path) }
            .to raise_error KeyError, error_message
        end
      end

      describe 'with path: a partially-valid scoped path' do
        let(:path)  { %w[path from here to there] }
        let(:value) { 'a maze of twisting passages, all alike' }
        let(:error_message) do
          expected = 'from'

          "key not found: #{expected.inspect}"
        end

        it 'should raise an exception' do
          expect { state.delete(*path) }
            .to raise_error KeyError, error_message
        end
      end

      describe 'with path: an invalid property of an object' do
        let(:path)          { %w[user password] }
        let(:value)         { 'l3tm31n' }
        let(:error_message) { /undefined method 'password='/ }

        it 'should raise an exception' do
          expect { state.delete(*path) }
            .to raise_error NoMethodError, error_message
        end
      end

      describe 'with path: a valid String' do
        let(:path) { %w[secret] }

        include_deferred 'should update the value'
      end

      describe 'with path: a valid Symbol' do
        let(:path) { %i[secret] }

        include_deferred 'should update the value'
      end

      describe 'with path: an existing path' do
        let(:path) { %w[path to scoped_value] }

        include_deferred 'should update the value'
      end

      describe 'with path: a valid property of an object' do
        let(:path) { %w[user name] }

        include_deferred 'should update the value'
      end

      describe 'with path: a nested property of an object' do
        let(:path) { %w[user data role] }

        include_deferred 'should update the value'
      end
    end
  end

  describe '#fetch' do
    deferred_examples 'should raise a KeyError' do |expected_key = nil|
      let(:error_message) do
        expected = expected_key&.inspect || path.map(&:inspect).join(', ')

        "key not found: #{expected}"
      end

      it 'should raise an exception' do
        expect { state.fetch(*path) }
          .to raise_error KeyError, error_message
      end
    end

    deferred_examples 'should return the default value' do
      describe 'with default: block' do
        let(:default_block) do
          ->(key = nil) { "default value: #{key.inspect}" }
        end
        let(:expected) do
          value = path.last
          value = value.to_s if value.is_a?(Symbol)

          "default value: #{value.inspect}"
        end

        it { expect(state.fetch(*path, &default_block)).to be == expected }
      end

      describe 'with default: value' do
        let(:default_value) { 'default value' }

        it 'should return the default value' do
          expect(state.fetch(*path, default: default_value))
            .to be == default_value
        end
      end
    end

    it 'should define the method' do
      expect(state)
        .to respond_to(:fetch)
        .with_unlimited_arguments
        .and_keywords(:default)
        .and_a_block
    end

    describe 'with nil' do
      let(:path) { [nil] }

      include_deferred 'should raise a KeyError'
    end

    describe 'with an Object' do
      let(:path) { [Object.new.freeze] }

      include_deferred 'should raise a KeyError'
    end

    describe 'with an empty String' do
      let(:path) { [''] }

      include_deferred 'should raise a KeyError'
    end

    describe 'with an empty Symbol' do
      let(:path) { [:''] }

      include_deferred 'should raise a KeyError', ''
    end

    describe 'with an invalid String' do
      let(:path) { ['invalid_key'] }

      include_deferred 'should raise a KeyError'

      include_deferred 'should return the default value'
    end

    describe 'with an invalid Symbol' do
      let(:path) { [:invalid_key] }

      include_deferred 'should raise a KeyError', 'invalid_key'

      include_deferred 'should return the default value'
    end

    wrap_deferred 'when initialized with an initial state' do
      describe 'with an invalid String' do
        let(:path) { %w[invalid_key] }

        include_deferred 'should raise a KeyError'

        include_deferred 'should return the default value'
      end

      describe 'with an invalid Symbol' do
        let(:path) { %i[invalid_key] }

        include_deferred 'should raise a KeyError', 'invalid_key'

        include_deferred 'should return the default value'
      end

      describe 'with an invalid scoped String' do
        let(:path) { %w[path to another_value] }

        include_deferred 'should raise a KeyError', 'another_value'

        include_deferred 'should return the default value'
      end

      describe 'with an invalid property of an object' do
        let(:path)          { %w[user password] }
        let(:error_message) { /undefined method 'password'/ }

        it 'should raise an exception' do
          expect { state.fetch(*path) }
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
        it { expect(state.fetch('path', 'to', 'scoped_value')).to be :value }
      end

      describe 'with a valid scoped Symbol' do
        it { expect(state.fetch(:path, :to, :scoped_value)).to be :value }
      end

      describe 'with a valid property of an object' do
        it { expect(state.fetch('user', 'name')).to be == 'Alan Bradley' }
      end
    end
  end

  describe '#get' do
    it { expect(state).to respond_to(:get).with_unlimited_arguments }

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
        it { expect(state.get('path', 'to', 'scoped_value')).to be :value }
      end

      describe 'with a valid scoped Symbol' do
        it { expect(state.get(:path, :to, :scoped_value)).to be :value }
      end

      describe 'with a valid property of an object' do
        it { expect(state.get('user', 'name')).to be == 'Alan Bradley' }
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
        it { expect(state.get('path', 'to', 'scoped_value')).to be :value }
      end

      describe 'with a scoped Symbol' do
        it { expect(state.get(:path, :to, :scoped_value)).to be :value }
      end

      describe 'with a property of an object' do
        it { expect(state.get('user', 'name')).to be == 'Alan Bradley' }
      end
    end
  end

  describe '#set' do
    deferred_examples 'should update the value' do
      it { expect(state.set(*path, value:, **options)).to be_a described_class }

      it 'should set the value on the returned state' do
        updated = state.set(*path, value:, **options)

        expect(updated.get(*path)).to be == value
      end
    end

    let(:value)   { :value }
    let(:options) { {} }

    it 'should define the method' do
      expect(state)
        .to respond_to(:set)
        .with(1).argument
        .and_unlimited_arguments
        .and_keywords(:intermediate_path, :value)
    end

    describe 'with path: nil' do
      let(:error_message) do
        tools.assertions.error_message_for(:presence, as: 'path')
      end

      it 'should raise an exception' do
        expect { state.set(nil, value:) }
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with path: an Object' do
      let(:error_message) do
        tools.assertions.error_message_for(:name, as: 'path')
      end

      it 'should raise an exception' do
        expect { state.set(Object.new.freeze, value:) }
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with path: an empty String' do
      let(:error_message) do
        tools.assertions.error_message_for(:presence, as: 'path')
      end

      it 'should raise an exception' do
        expect { state.set('', value:) }
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with path: an empty Symbol' do
      let(:error_message) do
        tools.assertions.error_message_for(:presence, as: 'path')
      end

      it 'should raise an exception' do
        expect { state.set(:'', value:) }
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with path: an invalid String' do
      let(:error_message) do
        'path must be a String containing only lowercase letters, digits, ' \
          'underscores, and dashes'
      end

      it 'should raise an exception' do
        expect { state.set('InvalidFormat', value:) }
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with path: an invalid Symbol' do
      let(:error_message) do
        'path must be a String containing only lowercase letters, digits, ' \
          'underscores, and dashes'
      end

      it 'should raise an exception' do
        expect { state.set(:InvalidFormat, value:) }
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with path: a scoped path with missing segments' do
      let(:path)  { %w[weapons swords longsword] }
      let(:value) { 'zweihänder' }
      let(:error_message) do
        expected = 'weapons'

        "key not found: #{expected.inspect}"
      end

      it 'should raise an exception' do
        expect { state.set(*path, value:) }
          .to raise_error KeyError, error_message
      end

      describe 'with intermediate_path: true' do
        let(:options) { super().merge(intermediate_path: true) }

        include_deferred 'should update the value'
      end
    end

    describe 'with path: a valid String' do
      let(:path)  { %w[checksum] }
      let(:value) { 0xdeadbeef }

      include_deferred 'should update the value'
    end

    describe 'with path: a valid Symbol' do
      let(:path)  { %i[checksum] }
      let(:value) { 0xdeadbeef }

      include_deferred 'should update the value'
    end

    wrap_deferred 'when initialized with an initial state' do
      describe 'with path: an invalid String' do
        let(:error_message) do
          'path must be a String containing only lowercase letters, digits, ' \
            'underscores, and dashes'
        end

        it 'should raise an exception' do
          expect { state.set('InvalidFormat', value:) }
            .to raise_error ArgumentError, error_message
        end
      end

      describe 'with path: an invalid Symbol' do
        let(:error_message) do
          'path must be a String containing only lowercase letters, digits, ' \
            'underscores, and dashes'
        end

        it 'should raise an exception' do
          expect { state.set(:InvalidFormat, value:) }
            .to raise_error ArgumentError, error_message
        end
      end

      describe 'with path: a scoped path with missing segments' do
        let(:path)  { %w[weapons swords longsword] }
        let(:value) { 'zweihänder' }
        let(:error_message) do
          expected = 'weapons'

          "key not found: #{expected.inspect}"
        end

        it 'should raise an exception' do
          expect { state.set(*path, value:) }
            .to raise_error KeyError, error_message
        end

        describe 'with intermediate_path: true' do
          let(:options) { super().merge(intermediate_path: true) }

          include_deferred 'should update the value'
        end
      end

      describe 'with path: a partially-valid scoped path' do
        let(:path)  { %w[path from here to there] }
        let(:value) { 'a maze of twisting passages, all alike' }
        let(:error_message) do
          expected = 'from'

          "key not found: #{expected.inspect}"
        end

        it 'should raise an exception' do
          expect { state.set(*path, value:) }
            .to raise_error KeyError, error_message
        end

        describe 'with intermediate_path: true' do
          let(:options) { super().merge(intermediate_path: true) }

          include_deferred 'should update the value'
        end
      end

      describe 'with path: an invalid property of an object' do
        let(:path)          { %w[user password] }
        let(:value)         { 'l3tm31n' }
        let(:error_message) { /undefined method 'password='/ }

        it 'should raise an exception' do
          expect { state.set(*path, value:) }
            .to raise_error NoMethodError, error_message
        end
      end

      describe 'with path: a valid String' do
        let(:path)  { %w[checksum] }
        let(:value) { 0xdeadbeef }

        include_deferred 'should update the value'
      end

      describe 'with path: a valid Symbol' do
        let(:path)  { %i[checksum] }
        let(:value) { 0xdeadbeef }

        include_deferred 'should update the value'
      end

      describe 'with path: an existing path' do
        let(:path)  { %w[secret] }
        let(:value) { '[redacted]' }

        include_deferred 'should update the value'
      end

      describe 'with path: a valid property of an object' do
        let(:path)  { %w[user name] }
        let(:value) { 'Kevin Flynn' }

        include_deferred 'should update the value'
      end

      describe 'with path: a nested property of an object' do
        let(:path)    { %w[user data role] }
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

  describe '#to_h' do
    it { expect(state).to respond_to(:to_h).with(0).arguments }

    it { expect(state.to_h).to be == initial_state }

    it 'should return a copy of the state' do
      copy = state.to_h

      expect { copy['checksum'] = 0xdeadbeef }.not_to change(state, :to_h)
    end

    context 'when the state is updated' do
      let(:expected) { initial_state.merge('checksum' => 0xdeadbeef) }

      before(:example) { state.set('checksum', value: 0xdeadbeef) }

      it { expect(state.to_h).to be == expected }
    end

    wrap_deferred 'when initialized with an initial state' do
      let(:initial_state) do
        {
          'address' => Spec::Address.new(street: '123 Example Rd'),
          'path'    => { 'to' => { 'scoped_value' => :value } },
          'roles'   => Set.new(%w[admin user]),
          'secrets' => [1, 2, 3, 4, 5],
          'user'    => Struct.new(:name, :data).new('Alan Bradley', {})
        }
      end

      example_constant 'Spec::Address' do
        Struct.new(:street)
      end

      it { expect(state.to_h).to be == initial_state }

      it 'should copy state Arrays' do
        copy = state.to_h

        expect { copy['secrets'] << 6 }.not_to change(state, :to_h)
      end

      it 'should copy state Hashes' do
        copy = state.to_h

        expect { copy['path']['to']['other_value'] = :other }
          .not_to change(state, :to_h)
      end

      it 'should copy state Sets' do
        copy = state.to_h

        expect { copy['roles'] << 'hacker' }.not_to change(state, :to_h)
      end

      it 'should not copy other objects' do
        copy = state.to_h

        expect { copy['address'].street = '234 Example St' }
          .to change(state, :to_h)
      end

      context 'when the state is updated' do
        let(:expected) { initial_state.merge('checksum' => 0xdeadbeef) }

        before(:example) { state.set('checksum', value: 0xdeadbeef) }

        it { expect(state.to_h).to be == expected }
      end
    end
  end
end
