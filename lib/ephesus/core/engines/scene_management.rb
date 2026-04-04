# frozen_string_literal: true

require 'sleeping_king_studios/tools/toolbox/mixin'

require 'ephesus/core/abstract'
require 'ephesus/core/engines'

module Ephesus::Core::Engines
  # Methods for managing scene pools for engines.
  module SceneManagement
    extend  SleepingKingStudios::Tools::Toolbox::Mixin
    include Ephesus::Core::Abstract
    include Ephesus::Core::Messaging::Subscriber

    UNDEFINED = SleepingKingStudios::Tools::UNDEFINED
    private_constant :UNDEFINED

    # Exception raised when unable to find a scene pool for the requested type.
    class SceneNotFoundError < StandardError; end

    # Methods extended onto the class when including StateManagement.
    module ClassMethods
      # @overload manage_scene(builder, scene_type: nil, **options)
      #   Registers a scene pool for scenes of the builder's or specified type.
      #
      #   Uses builder.scene_class::Pool if defined; otherwise uses Scenes::Pool
      #   as the base pool class.
      #
      #   @param builder [Ephesus::Core::Builder] the builder used to generate
      #     scenes for the scene pool.
      #   @param scene_type [String, #type, nil] the scene type to register.
      #     Defaults to the builder type.
      #   @param options [Hash] additional options for the scene pool.
      #
      #   @return [String] the registered scene type.
      #
      # @overload manage_scene(pool_class, scene_type:, **options)
      #   Registers a scene pool for scenes of the pool's or specified type.
      #
      #   @param pool_class [Class] the pool class to register.
      #   @param scene_type [String, #type,] the scene type to register.
      #   @param options [Hash] additional options for the scene pool.
      #
      #   @return [String] the registered scene type.
      #
      # @overload manage_scene(scene_class, scene_type: nil, **options)
      #   Registers a scene pool for scenes of the scene's or specified type.
      #
      #   Uses scene_class::Pool and scene_class::Builder if defined; otherwise
      #   uses Scenes::Pool and Scenes::Builder.
      #
      #   @param scene_class [Class] the scene class for the pool.
      #   @param scene_type [String, #type, nil] the scene type to register.
      #     Defaults to the scene type.
      #   @param options [Hash] additional options for the scene pool.
      #
      #   @return [String] the registered scene type.
      def manage_scene(value, scene_type: UNDEFINED, **) # rubocop:disable Metrics/MethodLength
        if abstract?
          raise self::AbstractClassError,
            "unable to manage scene for abstract class #{name}"
        end

        scene_type = normalize_scene_type(scene_type)

        pool_class, resolved_type = resolve_pool_and_type(value, scene_type, **)

        resolved_type = nil if resolved_type == UNDEFINED

        scene_type = resolved_type if scene_type == UNDEFINED

        validate_scene_type(scene_type)

        scene_type = scene_type.to_s

        own_managed_scenes[scene_type] = pool_class

        scene_type
      end

      # @return [Hash{String, Class}] the scene pools managed by the engine.
      def managed_scenes
        unless superclass.respond_to?(:managed_scenes, true)
          return own_managed_scenes
        end

        superclass.managed_scenes.merge(own_managed_scenes)
      end

      private

      def apply_pool_class(pool_class, builder, **)
        parameters = pool_class.instance_method(:initialize).parameters

        if parameters.first == %i[req builder]
          pool_class.subclass(builder, **)
        else
          pool_class.subclass(**)
        end
      end

      def builder_class_for(scene_class)
        return scene_class::Builder if scene_class.const_defined?(:Builder)

        Ephesus::Core::Scenes::Builder
      end

      def initialize_builder(builder_class, scene_class)
        parameters = builder_class.instance_method(:initialize).parameters

        if parameters.first == %i[req scene_class]
          builder_class.new(scene_class)
        else
          builder_class.new
        end
      end

      def normalize_scene_type(scene_type)
        return scene_type if scene_type == UNDEFINED

        scene_type = scene_type.type if scene_type.respond_to?(:type)
        scene_type = scene_type.to_s if scene_type.is_a?(Symbol)
        scene_type
      end

      def own_managed_scenes = @own_managed_scenes ||= {}

      def pool_class?(value)
        value.is_a?(Class) && value < Ephesus::Core::Scenes::Pool
      end

      def pool_class_for(scene_class)
        return scene_class::Pool if scene_class.const_defined?(:Pool)

        Ephesus::Core::Scenes::Pool
      end

      def resolve_builder_and_pool(value) # rubocop:disable Metrics/MethodLength
        if value.is_a?(Ephesus::Core::Scenes::Builder)
          builder      = value
          pool_class   = pool_class_for(builder.scene_class)

          return [builder, pool_class]
        end

        if value.is_a?(Class) && value < Ephesus::Core::Scene
          scene_class   = value
          pool_class    = pool_class_for(scene_class)
          builder_class = builder_class_for(scene_class)
          builder       = initialize_builder(builder_class, scene_class)

          return [builder, pool_class]
        end

        raise ArgumentError,
          'value is not a Scenes::Builder instance, a Scenes::Pool class or ' \
          'a Scene class'
      end

      def resolve_pool_and_type(value, scene_type, **)
        return [value.subclass(type: scene_type, **), nil] if pool_class?(value)

        builder, pool_class = resolve_builder_and_pool(value)

        scene_type = value.type if scene_type == UNDEFINED
        pool_class = apply_pool_class(pool_class, builder, type: scene_type, **)

        [pool_class, value.type]
      end

      def tools = @tools ||= SleepingKingStudios::Tools::Toolbelt.instance

      def validate_scene_type(scene_type)
        Ephesus::Core::Messages::Typing
          .validate_type(scene_type, as: 'scene_type')
      end
    end

    def initialize
      super

      @scene_pools = initialize_scene_pools
      @scenes      = {}
    end

    # Finds or creates a scene with the given type and options.
    #
    # @param scene_type [String] the type of scene to request.
    # @param scene_options [Hash] additional options for the scene.
    #
    # @return [Ephesus::Core::Scene] the matched scene.
    #
    # @raise [Ephesus::Core::Engines::SceneManagement::SceneNotFoundError] if
    #   there is no scene pool matching the requested type.
    def get_scene(scene_type, **scene_options)
      scene_pool = scene_pools.fetch(scene_type) do
        message =
          "unable to get scene #{scene_type.inspect} - no scene pool " \
          'matching the requested scene type'

        raise SceneNotFoundError, message
      end

      scene_pool.get(**scene_options)
    end

    # Handler called when a scene is added by a scene pool
    #
    # @param message [Ephesus::Core::Scenes::Pool::SceneAdded] the received
    #   message.
    #
    # @return [void]
    def handle_scene_added(message)
      @scenes[message.scene.id] = message.scene
    end

    private

    attr_reader :scenes

    attr_reader :scene_pools

    def initialize_scene_pools # rubocop:disable Metrics/MethodLength
      self
        .class
        .managed_scenes
        .transform_values(&:new)
        .each_value do |pool|
          subscribe(
            pool,
            channel:     :scene_added,
            method_name: :handle_scene_added
          )
        end
    end
  end
end
