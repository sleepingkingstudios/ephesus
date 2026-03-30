# frozen_string_literal: true

require 'cuprum/command'

require 'ephesus/core/scenes'

module Ephesus::Core::Scenes
  # Builder object for generating a Scene from a set of input parameters.
  class Builder < Cuprum::Command
    # @param scene_class [Class] the class of Scene to build.
    # @param static_options [Hash] options used to generate the Scene.
    def initialize(scene_class, **static_options)
      super()

      @scene_class    = scene_class
      @static_options = static_options
    end

    # @return [Class] the class of Scene to build.
    attr_reader :scene_class

    # @return [Hash] options used to generate the Scene.
    attr_reader :static_options

    # @!method call(**options)
    #   Builds and returns an instance of the scene class.
    #
    #   @param options [Hash] options used to generate the Scene. These options
    #     will be merged atop the static options defined for the builder.
    #
    #   @return [Cuprum::Result<Ephesus::Core::Scene>] the generated scene.
    alias build call

    private

    def build_scene(state, **) = scene_class.new(state:)

    def build_state(**) = {}

    def process(**options)
      options = static_options.merge(options)
      state   = step { build_state(**options) }

      build_scene(state, **options)
    end
  end
end
