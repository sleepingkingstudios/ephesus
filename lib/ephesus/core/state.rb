# frozen_string_literal: true

require 'ephesus/core'

module Ephesus::Core
  # Defines an immutable-compatible interface for accessing and updating state.
  class State
    # Format used to validate state paths.
    FORMAT = /\A[a-z0-9\-_]+(\.[a-z0-9\-_]+)*\z/

    UNDEFINED = SleepingKingStudios::Tools::UNDEFINED
    private_constant :UNDEFINED

    class << self
      # Verifies that the given path is a valid state path.
      #
      # If the given value is not a properly formatted String, raises an
      # ArgumentError.
      #
      # @param path [Object] the path to validate.
      # @param as [String] the label used to generate error messages. Defaults
      #   to "path".
      #
      # @return [String] the validated path.
      def validate_path(path, as: 'path')
        tools.assertions.validate_name(path, as:)

        message =
          "#{as} must be sequences of lowercase letters, digits, " \
          'underscores, or dashes, separated by periods'

        tools.assertions.validate_matches(
          path.to_s,
          expected: FORMAT,
          message:
        )

        path.to_s
      end

      private

      def tools = SleepingKingStudios::Tools::Toolbelt.instance
    end

    # @overload initialize(initial_state)
    #   @param initial_state [Hash{String => Object}] the initial state value.
    def initialize(state, normalize: true)
      tools
        .assertions
        .validate_instance_of(state, as: 'initial_state', expected: Hash)

      @state = normalize ? normalize_state(state) : state
    end

    # @overload fetch(path)
    #   Retrieves the value at the given scoped path.
    #
    #   @param path [String] the scoped path. Must be a lowercase, underscored
    #     String separated by periods.
    #
    #   @return [Object, nil] the object at the given path.
    #
    #   @raise [KeyError, NoMethodError] if the path is invalid.
    #
    # @overload fetch(path, default)
    #   Retrieves the value at the given scoped path.
    #
    #   @param path [String] the scoped path. Must be a lowercase, underscored
    #     String separated by periods.
    #   @param default [Object] the default value if the path is not valid.
    #
    #   @return [Object] the object at the given path, or the default value if
    #     the path is invalid.
    #
    # @overload fetch(path) { |key| ... }
    #   Retrieves the value at the given scoped path.
    #
    #   @param path [String] the scoped path. Must be a lowercase, underscored
    #     String separated by periods.
    #
    #   @yieldparam key [String] the non-matching path segment.
    #
    #   @yieldreturn [Object] the default value if the path is not valid.
    #
    #   @return [Object] the object at the given path, or the value returned by
    #     the block if the path is invalid.
    def fetch(path, default = UNDEFINED, &)
      raise KeyError, "key not found: #{path.inspect}" unless valid_path?(path)

      path
        .to_s
        .split('.')
        .reduce(@state) { |data, key| fetch_item(data, key, default, &) }
    end

    # Retrieves the value at the given scoped path.
    #
    # @param path [String] the scoped path. Must be a lowercase, underscored
    #   String separated by periods.
    #
    # @return [Object, nil] the object at the given path, or nil if the path is
    #   invalid.
    def get(path)
      return unless valid_path?(path)

      path.to_s.split('.').reduce(@state) { |data, key| get_item(data, key) }
    end

    # Assigns the value at the given scoped path.
    #
    # @param path [String] the scoped path. Must be a lowercase, underscored
    #   String separated by periods.
    # @param value [Object] the value to assign.
    # @param intermediate_path [true, false] if true, creates and assigns empty
    #   Hashes for intermediate path segments as required. Otherwise, the full
    #   path prefix must exist.
    #
    # @return [State] an instance of the State class
    def set(path, value, intermediate_path: false)
      Ephesus::Core::State.validate_path(path, as: 'path')

      *path, key = path.to_s.split('.')

      data = resolve_path(*path, intermediate_path:)

      set_item(data, key, value)

      self
    end

    private

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
      return false unless path.is_a?(String) || path.is_a?(Symbol)

      !path.empty?
    end
  end
end
