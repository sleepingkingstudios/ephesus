# frozen_string_literal: true

require 'forwardable'
require 'observer'
require 'securerandom'

Bundler.require(:default, :development)

require 'cuprum'
require 'plumbum'
require 'stannum'

require 'ephesus/core'

module Ephesus::Core
  module Engines
    module AsynchronousEngine
      def initialize(**)
        super(**)

        @running      = false
        @threads      = Set.new
        @thread_count = 1
        @thread_wait  = 1.0
      end

      attr_reader :thread_count

      attr_reader :thread_wait

      def running? = @running

      def start
        raise 'already running' if @running

        @running = true

        puts 'Starting...'

        @thread_count.times do
          puts 'Creating threads...'

          @threads << Thread.new do
            puts "Calling next scene..."

            start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)

            call_next_scene

            sleep @thread_wait
          end

          puts 'Done!'
        end

        self
      end

      def stop
        @threads.each(&:join)

        @threads = Set.new
        @running = false

        self
      end

      # private

      def call_next_scene
        #

        scenes.each_value
      end
    end

    module SynchronousEngine
      private

      def enqueue_event(event:, scene:)
        super.tap { scene.call }
      end
    end
  end

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
engine  = Exploration::Engine.new
engine.extend(Ephesus::Core::Engines::SynchronousEngine)
# engine.send(:initialize)

engine.add_connection(player1)
engine.add_connection(player2)

scene = engine.get_scene(Exploration::Scene, area: 'hollow_town')

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
