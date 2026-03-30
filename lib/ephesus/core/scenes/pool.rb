# frozen_string_literal: true

require 'ephesus/core/scenes'

module Ephesus::Core::Scenes
  # Utility class that provides scenes of a given type to an Engine.
  class Pool
    # Exception raised when unable to build a scene with the requested options.
    class BuildError < StandardError; end

    # @param builder [Ephesus::Core::Scenes::Builder] the builder used to
    #   initialize new scenes for the pool.
    def initialize(builder)
      @builder   = builder
      @grouped   = Hash.new { |hsh, key| hsh[key] = [] }
      @semaphore = Thread::Mutex.new
    end

    # @return [Ephesus::Core::Scenes::Builder] the builder used to initialize
    #   new scenes for the pool.
    attr_reader :builder

    # Finds or creates a scene matching the given options.
    def get(**options)
      semaphore.synchronize do
        group = grouped[options.hash]
        scene = group.first

        return scene if scene

        scene = build_scene(**options)

        group << scene

        scene
      end
    end

    private

    attr_reader :grouped

    attr_reader :semaphore

    def build_error_message_for(error:, options:)
      message = 'unable to build scene'

      unless options.empty?
        message = "#{message} with options #{options.inspect}"
      end

      message = "#{message} - #{error.message}" if error

      message
    end

    def build_scene(**options)
      result = builder.call(**options)

      return result.value if result.success?

      message = build_error_message_for(error: result.error, options:)

      raise BuildError, message
    end
  end
end
