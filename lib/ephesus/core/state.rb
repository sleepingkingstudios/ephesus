# frozen_string_literal: true

require 'ephesus/core'

module Ephesus::Core
  # Defines an immutable-compatible interface for accessing and updating state.
  class State # rubocop:disable Metrics/ClassLength
    # Format used to validate state paths.
    FORMAT = /\A[a-z0-9\-_]+\z/

    UNDEFINED = SleepingKingStudios::Tools::UNDEFINED
    private_constant :UNDEFINED

    class << self
      # @overload validate_path(*path, as: 'path')
      #   Verifies that the given path is a valid state path.
      #
      #   If the given value is not an Array of properly formatted Strings,
      #   raises an ArgumentError.
      #
      #   @param path [Array<Object>] the path to validate.
      #   @param as [String] the label used to generate error messages. Defaults
      #     to "path".
      #
      #   @return [Array<String>] the validated path.
      def validate_path(first, *rest, as: 'path')
        return [validate_segment(first, as:)] if rest.empty?

        [first, *rest].map.with_index do |segment, index|
          validate_segment(segment, as:, index:)
        end
      end

      private

      def tools = SleepingKingStudios::Tools::Toolbelt.instance

      def validate_segment(segment, as:, index: nil) # rubocop:disable Metrics/MethodLength
        as = "#{as}[#{index}]" if index

        tools.assertions.validate_name(segment, as:)

        message =
          "#{as} must be a String containing only lowercase letters, digits, " \
          'underscores, and dashes'

        tools.assertions.validate_matches(
          segment.to_s,
          expected: FORMAT,
          message:
        )

        segment.to_s
      end
    end

    # @overload initialize(initial_state)
    #   @param initial_state [Hash{String => Object}] the initial state value.
    def initialize(state, normalize: true)
      tools
        .assertions
        .validate_instance_of(state, as: 'initial_state', expected: Hash)

      @state = normalize ? normalize_state(state) : state
    end

    # Compares the state with the other object.
    #
    # @param other [Object] the object to compare.
    #
    # @return [true, false] true if the other object is a State with identical
    #   state; otherwise false.
    def ==(other)
      other.is_a?(Ephesus::Core::State) && to_h == other.to_h
    end

    # @overload fetch(path)
    #   Retrieves the value at the given scoped path.
    #
    #   @param path [Array<String>] the scoped path. Must be a non-empty list of
    #     lowercase, underscored Strings.
    #
    #   @return [Object, nil] the object at the given path.
    #
    #   @raise [KeyError, NoMethodError] if the path is invalid.
    #
    # @overload fetch(path, default:)
    #   Retrieves the value at the given scoped path.
    #
    #   @param path [Array<String>] the scoped path. Must be a non-empty list of
    #     lowercase, underscored Strings.
    #   @param default [Object] the default value if the path is not valid.
    #
    #   @return [Object] the object at the given path, or the default value if
    #     the path is invalid.
    #
    # @overload fetch(path) { |key| ... }
    #   Retrieves the value at the given scoped path.
    #
    #   @param path [Array<String>] the scoped path. Must be a non-empty list of
    #     lowercase, underscored Strings.
    #
    #   @yieldparam key [String] the non-matching path segment.
    #
    #   @yieldreturn [Object] the default value if the path is not valid.
    #
    #   @return [Object] the object at the given path, or the value returned by
    #     the block if the path is invalid.
    def fetch(*path, default: UNDEFINED, &)
      unless valid_path?(path)
        raise KeyError, "key not found: #{inspect_path(path)}"
      end

      path.reduce(@state) { |data, key| fetch_item(data, key.to_s, default, &) }
    end

    # Retrieves the value at the given scoped path.
    #
    # @param path [Array<String>] the scoped path. Must be a non-empty list of
    #   lowercase, underscored Strings.
    #
    # @return [Object, nil] the object at the given path, or nil if the path is
    #   invalid.
    def get(*path)
      return unless valid_path?(path)

      path.reduce(@state) { |data, key| get_item(data, key.to_s) }
    end

    # Generates a "pretty" human-readable representation of the state.
    def pretty_print(pp) = pp(@state) # rubocop:disable Lint/UnusedMethodArgument

    # Assigns the value at the given scoped path.
    #
    # @param path [Array<String>] the scoped path. Must be a non-empty list of
    #   lowercase, underscored Strings.
    # @param value [Object] the value to assign.
    # @param intermediate_path [true, false] if true, creates and assigns empty
    #   Hashes for intermediate path segments as required. Otherwise, the full
    #   path prefix must exist.
    #
    # @return [State] an instance of the State class
    def set(*path, value:, intermediate_path: false)
      *path, key = Ephesus::Core::State.validate_path(*path, as: 'path')

      data = resolve_path(*path, intermediate_path:)

      set_item(data, key, value)

      self
    end

    # @return [Hash] a Hash representation of the state.
    def to_h = deep_copy(@state)

    private

    def deep_copy(data)
      case data
      when Array
        data.map { |item| deep_copy(item) }
      when Hash
        data.to_h { |key, value| [key, deep_copy(value)] }
      when Set
        Set.new(data.map { |item| deep_copy(item) })
      else
        data
      end
    end

    def fetch_item(data, key, default = UNDEFINED, &)
      case data
      when Hash
        return data.fetch(key, &) if default == UNDEFINED

        data.fetch(key, default, &)
      else
        data.public_send(key)
      end
    end

    def get_item(data, key)
      case data
      when Hash then data[key]
      else data.public_send(key) if data.respond_to?(key)
      end
    end

    def inspect_path(path) = path.map(&:inspect).join(', ')

    def item?(data, key)
      case data
      when Hash then data.key?(key)
      else data.respond_to?(key)
      end
    end
    alias has_item? item?

    def normalize_state(state)
      tools.hash_tools.convert_keys_to_strings(state)
    end

    def resolve_path(*path, intermediate_path:)
      unless intermediate_path
        return path.reduce(@state) { |data, key| fetch_item(data, key) }
      end

      path.reduce(@state) do |data, key|
        next get_item(data, key) if has_item?(data, key)

        set_item(data, key, {})
      end
    end

    def set_item(data, key, value)
      case data
      when Hash then data[key] = value
      else data.public_send("#{key}=", value)
      end
    end

    def tools = @tools ||= SleepingKingStudios::Tools::Toolbelt.instance

    def valid_path?(path)
      return false if path.empty?

      path.all? { |item| item.is_a?(String) || item.is_a?(Symbol) }
    end
  end
end
