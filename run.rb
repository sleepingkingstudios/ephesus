# frozen_string_literal: true

require 'forwardable'
require 'observer'
require 'securerandom'

Bundler.require(:default, :development)

require 'cuprum'
require 'plumbum'
require 'stannum'

require 'ephesus/core'

# @todo
# - Investigate output formatting.
# - Investigate Scene management.
#   - Investigate Scenes::Pool ?
#   - Optional - can just use a Scene directly instead?
#   - Define a scene/scene_manager DSL on Engine?
#   - @see https://github.com/mperham/connection_pool ?
#
# ```ruby
# pool = Scenes::Pool.new(Exploration::Scene, min: 1, max: 5)
# pool.get(area: 'Hollow Town', difficulty: :hard, ironman: true)
# pool.get { |scene| scene.population < 100 }
# ```

Ephesus::Core::Connection.class_eval do
  include Ephesus::Core::Messaging::Subscriber

  def actor=(value)
    raise 'oh no' if actor

    @actor = value

    subscribe(
      actor,
      channel:     :notifications,
      method_name: :handle_notification
    )
  end

  def handle_notification(notification)
    result = formatter.format_output(notification:)

    if result.failure?
      # @todo: Handle failure here by notifying the connection.
      return
    end

    publish(result.value, channel: :output)
  end
end

module Ephesus::Core
  module Formats
    module Commands
      class FormatOutput < Cuprum::Command
        def initialize(**options)
          @options = options
        end

        attr_reader :options

        private

        def process(notification)
          failure(unhandled_notification_error(notification))
        end

        def unhandled_notification_error(notification)
          Ephesus::Core::Formats::Errors::UnhandledNotification
            .new(notification:)
        end
      end
    end

    module Errors
      class OutputError < Cuprum::Error
        TYPE = 'ephesus.core.formats.errors.output_error'

        def initialize(message:, notification:)
          @notification = notification

          super
        end

        attr_reader :notification

        private

        def as_json_data
          { 'notification' => notification.as_json }
        end
      end

      class UnhandledNotification < OutputError
        TYPE = 'ephesus.core.formats.errors.unhandled_notification'

        def initialize(notification:)
          @notification = notification

          super(message: default_message, notification:)
        end

        private

        def default_message
          message    = "Unhandled notification #{notification.type.inspect}"
          properties =
            notification
            .to_h
            .except(:current_actor, :original_actor, :context)
            .map { |key, value| "#{key}: #{value.inspect}" }

          return message if properties.empty?

          "#{message} with properties #{properties.join ', '}"
        end
      end
    end

    Formatter.class_eval do
      def format_output(notification:, **)
        output_formatter_for(**).call(notification)
      end

      private

      def output_formatter_for(**)
        Ephesus::Core::Formats::Commands::FormatOutput.new(**)
      end
    end

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

  class Engine
    include Ephesus::Core::Messaging::Subscriber

    def initialize
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
    when Ephesus::Core::Formats::PlainText::OutputEvent
      puts "[#{connection.name}] #{message.text}"
    else
      raise 'oh no'
    end
  end
end

state = {
  'area' => Exploration::AREAS.fetch('hollow_town'),
  'node' => Exploration::NODES.fetch('town_square')
}
scene  = Exploration::Scene.new(state:)

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
