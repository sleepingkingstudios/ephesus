# frozen_string_literal: true

require 'ephesus/core'

# Development Process
#
# - Define Scenes
#   - For chat, each scene is a chat room.
# - Define Actors
#   - Who interacts with a scene? Users? Autonomous agents?
#   - What data do the actors need? In our case, need a name to post by.
# - Define Commands
#   - For a scene, how do the users interact?
#   - For chat app, by posting a message.
# - Define Formats
#   - For each format:
#     - For each command input, how does the the user input it?
#     - For each command output, how is it presented to the user?
#     - How are error outputs presented to the user?
#     - How are non-command outputs presented to the user? E.g. user joined channel.
# - Define Engine

module Ephesus::Core
  module Engines
    module AsynchronousEngine
      def start
        @barrier = Async::Barrier.new
        @workers = Async::Semaphore.new(worker_limit, parent: @barrier)
      end

      def stop
        @barrier.wait
      end

      private

      def enqueue_event(event:, scene:)
        super.tap do
          @workers.async { scene.call }
        end
      end

      def worker_limit = 5
    end

    module SynchronousEngine
      private

      def enqueue_event(event:, scene:)
        super.tap { scene.call(thread_safe: false) }
      end
    end
  end
end

module Examples
  module Chat
    class Actor < Ephesus::Core::Actor
      def initialize(name:)
        @name = name

        super()
      end

      attr_reader :name

      def handle_connection_update(message)
        super

        return unless message.data.key?(:name)

        @name = message.data[:name]
      end
    end

    module Commands
      class PublishMessage < Ephesus::Core::Command
        Event = Ephesus::Core::Message.define(:actor, :text)

        Notification = Ephesus::Core::Messages::Notification.define(:text)

        private

        def process(event:, state:)
          actor = event.actor

          if event.actor.name
            messages = state.get('messages').push([actor.id, event.text])

            notify(text: event.text)
          else
            side_effects << [:update_connection, actor.id, { name: event.text }]

            notify(ConnectActor::Notification, actor:)
          end

          success
        end
      end

      class ConnectActor < Ephesus::Core::Commands::ConnectActor
        NameRequiredNotification = Ephesus::Core::Messages::Notification.define

        Notification = Ephesus::Core::Messages::Notification.define(:actor)

        private

        def process(event:, state:)
          super

          actor = event.actor

          if actor.name
            notify(actor:)
          else
            notify(NameRequiredNotification, current_actor: actor)
          end

          success
        end
      end
    end

    module Formats
      module PlainText
        module Commands
          class FormatInput < Ephesus::Core::Formats::Commands::FormatInput
            private

            def format_input(input_event)
              actor = input_event.connection.actor
              text  = input_event.text

              Examples::Chat::Commands::PublishMessage::Event.new(actor:, text:)
            end
          end

          class FormatOutput < Ephesus::Core::Formats::Commands::FormatOutput
            private

            def format_error_notification(notification)
              # @todo: Show full error details in dev/test environments?
              Ephesus::Core::Formats::PlainText::ErrorMessage.new(
                error:    notification.error,
                error_id: notification.error_id,
                details:  notification.details,
                format:,
                message:  notification.message,
                text:     "#{notification.class.name}: #{notification.message}"
              )
            end

            def format_output(notification)
              commands = Examples::Chat::Commands

              case notification.type
              when commands::ConnectActor::Notification.type
                actor_name = notification.original_actor.name

                Ephesus::Core::Formats::PlainText::OutputMessage.new(
                  text: "#{actor_name} has joined the channel."
                )
              when commands::ConnectActor::NameRequiredNotification.type
                Ephesus::Core::Formats::PlainText::OutputMessage.new(
                  text: 'Enter your name:'
                )
              when commands::PublishMessage::Notification.type
                actor_name = notification.original_actor.name

                Ephesus::Core::Formats::PlainText::OutputMessage.new(
                  text: "#{actor_name}: #{notification.text}"
                )
              else
                super
              end
            end
          end
        end

        class Formatter
          include Ephesus::Core::Formats::Formatter
          include Ephesus::Core::Messages::Typing

          TYPE = Ephesus::Core::Formats::PlainText.type

          private

          def input_formatter_for(**)
            Examples::Chat::Formats::PlainText::Commands::FormatInput.new(**)
          end

          def output_formatter_for(**)
            Examples::Chat::Formats::PlainText::Commands::FormatOutput.new(**)
          end
        end
      end
    end

    module Scenes
      class ChatRoom < Ephesus::Core::Scene
        class Builder < Ephesus::Core::Scenes::Builder
          private

          def build_state
            { 'messages' => [] }
          end
        end

        handle_event Examples::Chat::Commands::ConnectActor,
          event_type: Ephesus::Core::Commands::ConnectActor
        handle_event Examples::Chat::Commands::PublishMessage
      end
    end

    class Engine < Ephesus::Core::Engine
      manage_scene Examples::Chat::Scenes::ChatRoom

      private

      def build_actor(connection)
        Examples::Chat::Actor.new(name: connection.data[:name])
      end

      def default_scene
        get_scene Examples::Chat::Scenes::ChatRoom
      end
    end
  end
end
