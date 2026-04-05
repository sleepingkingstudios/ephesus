# frozen_string_literal: true

require 'sleeping_king_studios/tools/toolbox/subclass'

require 'ephesus/core/messaging/publisher'
require 'ephesus/core/scenes'

module Ephesus::Core::Scenes
  # Utility class that provides scenes of a given type to an Engine.
  class Pool
    extend  SleepingKingStudios::Tools::Toolbox::Subclass
    include Ephesus::Core::Messaging::Publisher

    # Exception raised when unable to build a scene with the requested options.
    class BuildError < StandardError; end

    # Message dispatched when a scene is added to the pool.
    SceneAdded = Ephesus::Core::Message.define(:scene, :type)

    # @param builder [Ephesus::Core::Scenes::Builder] the builder used to
    #   initialize new scenes for the pool.
    # @param type [String] the type identifier for the scene pool. Defaults to
    #   the type identifier for the builder.
    # @param options [Hash] additional options for the pool.
    def initialize(builder, type: nil, **options)
      @builder   = builder
      @type      = type || builder.type
      @options   = options
      @grouped   = Hash.new { |hsh, key| hsh[key] = [] }
      @semaphore = Thread::Mutex.new
    end

    # @return [Ephesus::Core::Scenes::Builder] the builder used to initialize
    #   new scenes for the pool.
    attr_reader :builder

    # @return [Hash] additional options for the pool.
    attr_reader :options

    # @return [String] the type identifier for the scene pool.
    attr_reader :type

    # Finds or creates a scene matching the given options.
    #
    # @param scene_options [Hash] options used to match or create the scene.
    #
    # @return [Ephesus::Core::Scene] the matched or created scene.
    def get(**scene_options)
      semaphore.synchronize do
        group = grouped[scene_options.hash]
        scene = group.first

        return scene if scene

        scene = build_scene(**scene_options)

        add_scene(group:, scene:)
      end
    end

    private

    attr_reader :grouped

    attr_reader :semaphore

    def add_scene(group:, scene:)
      group << scene

      publish(SceneAdded.new(scene:, type:), channel: :scene_added)

      scene
    end

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
