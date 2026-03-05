# frozen_string_literal: true

require 'forwardable'
require 'observer'
require 'securerandom'

Bundler.require(:default, :development)

require 'cuprum'
require 'plumbum'
require 'stannum'

require 'ephesus/core'

Ephesus::Core::Actor.class_eval do
  def inspect
    tools
      .object_tools
      .format_inspect(self, address: false, properties: properties_to_inspect)
  end

  private

  def properties_to_inspect = %i[id]

  def tools = @tools ||= SleepingKingStudios::Tools::Toolbelt.instance
end

Ephesus::Core::Message.class_eval do
  def inspect
    tools
      .object_tools
      .format_inspect(self, address: false, properties: properties_to_inspect)
  end

  private

  def properties_to_inspect = members
end

Ephesus::Core::Scenes::Builder.class_eval do
  def type = scene_class.type
end

Ephesus::Core::Scenes::Pool.class_eval do
  include SleepingKingStudios::Tools::Toolbox::Subclass
end

module Ephesus::Core
  module Formats
    module PlainText
      include Ephesus::Core::Messages::Typing

      InputEvent =
        Ephesus::Core::Messages::LazyConnectionMessage.define(:format, :text) do
          def initialize(**) = super(format: :text, **)
        end

      OutputEvent =
        Ephesus::Core::Message.define(:format, :original_type, :text) do
          def initialize(**) = super(format: :text, **)
        end

      module Errors
        class InvalidInputError < Ephesus::Core::Formats::Errors::InputError
          def initialize(input:, scene:)
            @input = input

            super(input:, message: default_message, scene:)
          end

          attr_reader :input

          private

          def as_json_data
            super().merge({ 'input' => input })
          end

          def default_message
            "Unable to parse input #{input}"
          end
        end
      end
    end
  end

  module Engines
    module SceneManagement
      extend SleepingKingStudios::Tools::Toolbox::Mixin

      module ClassMethods
        def scene(builder)
          scene_type, builder = [builder.type, builder]

          pool_class =
            if builder.scene_class.const_defined?(:Pool)
              builder.scene_class::Pool
            else
              Ephesus::Core::Scenes::Pool
            end

          # @todo: Subclass with config as well.

          managed_scenes[scene_type] = pool_class
        end

        def managed_scenes
          @managed_scenes ||= {}
        end
      end

      def initialize
        @scenes      = {}
        @scene_pools = initialize_scene_pools
      end

      attr_reader :scene_pools # VERY TEMPORARY

      private

      def initialize_scene_pools
        self.class.managed_scenes.transform_values(&:new)
      end
    end
  end

  class Engine
    include Ephesus::Core::Messaging::Subscriber
    include Ephesus::Core::Engines::SceneManagement

    def initialize
      super()

      @actors      = {}
      @connections = {}
      @scenes      = {}
    end

    def add_connection(connection)
      @connections[connection.id] = connection

      connection.actor = build_actor(connection)

      subscribe(
        connection,
        channel:     :events,
        method_name: :handle_event
      )
    end

    def add_scene(scene)
      @scenes[scene.id] = scene
    end

    def connect(actor:, scene:)
      (@actors[scene.id] ||= {})[actor.id] = actor

      event = Ephesus::Core::Commands::ConnectActor::Event.new(actor)
      scene.enqueue_event(event)
    end

    def handle_event(event)
      connection = event.connection
      scene      = scene_for(connection.actor)
      result     = connection.formatter.format_input(event:, scene:)

      if result.failure?
        # @todo: Handle failure here by notifying the connection.
        return
      end

      scene.enqueue_event(result.value)
      scene.call
    end

    def scene_for(actor)
      scene_id, _ = @actors.find { |_, actors| actors.key?(actor.id) }

      scene_id&.then { @scenes[scene_id] }
    end

    private

    def build_actor(connection) = Ephesus::Core::Actors::ExternalActor.new(connection:)
  end
end

require_relative './exploration'

class Client
  include Ephesus::Core::Messaging::Subscriber

  def initialize(connection)
    @connection = connection

    subscribe(connection, channel: :output, method_name: :handle_output)
  end

  attr_reader :connection

  def handle_output(message)
    case message
    when nil
      # Do nothing.
    when Ephesus::Core::Formats::ErrorMessage
      puts "[#{connection.name}] #{message.message}"
    when Ephesus::Core::Formats::PlainText::OutputEvent
      puts "[#{connection.name}] #{message.text}"
    else
      raise 'oh no'
    end
  end
end

pool  = Exploration::Scene::Pool.new
scene = pool.get(area: 'hollow_town')
# scene = pool.get(area: 'route_31')

player1 = Exploration::Connection.new(
  format: Ephesus::Core::Formats::PlainText.type,
  name:   'Aina Sahalin'
)
player2 = Exploration::Connection.new(
  format: Ephesus::Core::Formats::PlainText.type,
  name:   'Shiro Amada'
)
client1 = Client.new(player1)
client2 = Client.new(player2)

engine     = Exploration::Engine.new
engine.add_connection(player1)
engine.add_connection(player2)
engine.add_scene(scene)
engine.connect(actor: player1.actor, scene:)
scene.call
engine.connect(actor: player2.actor, scene:)
scene.call

events = [
  Ephesus::Core::Formats::PlainText::InputEvent.new(connection: player1, text: 'look around')
  # Exploration::Commands::Look::Event.new(actor:, target: nil),
  # Exploration::Commands::Look::Event.new(actor:, target: 'the old church'),
  # Exploration::Commands::Go::Event.new(
  #   actor:,
  #   target:      'the old church',
  #   target_type: :label
  # ),
  # Exploration::Commands::Look::Event.new(actor:, target: nil)
]

# scene.call

# connection.changed
# connection.notify_observers(event)
# scene.call

player1.handle_input(events.first)

# valid_event   = Exploration::Commands::Look::Event.new(actor: player1.actor, target: nil)
# invalid_event = events.first

# command = Ephesus::Core::Formats::Commands::FormatInput.new(scene:)
# result  = command.call(invalid_event)

# byebug
self
