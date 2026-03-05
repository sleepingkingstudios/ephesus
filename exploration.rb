# frozen_string_literal: true

require 'cuprum'
require 'stannum'

require 'ephesus/core'

module Exploration
  class Area
    include Stannum::Entity

    define_primary_key :id, String

    attribute :name, String
    attribute :slug, String

    association :many, 'Exploration::Node'
  end

  class Node
    include Stannum::Entity

    define_primary_key :id, String

    attribute :name,       String
    attribute :slug,       String
    attribute :short_desc, String, optional: true
    attribute :full_desc,  String, optional: true

    association :one,  'Exploration::Area', foreign_key: true
    association :many, 'Exploration::Edge'
  end

  class Edge
    include Stannum::Entity

    define_primary_key :id, String

    attribute :direction,  String, optional: true
    attribute :label,      String, optional: true
    attribute :short_desc, String, optional: true
    attribute :full_desc,  String, optional: true

    association :one, :source, class_name: 'Exploration::Node', inverse: :edges
    association :one, :target, class_name: 'Exploration::Node', inverse: false
  end

  class Connection < Ephesus::Core::Connection
    def initialize(format:, name:, **)
      formats = [
        Exploration::Formats::PlainText::Formatter
      ]
        .to_h { |format| [format.type, format] }

      super(format:, formats:, **)

      @name = name
    end

    attr_reader :name
  end

  class Character < Ephesus::Core::Actors::ExternalActor
    def name = connection.name
  end

  module Commands
    class Go < Ephesus::Core::Command
      Event = Ephesus::Core::Message.define(:actor, :target, :target_type)

      Notification = Ephesus::Core::Message.define(:description)

      private

      def edge_matches?(edge:, event:)
        case event.target_type
        when :label
          edge.label == event.target
        end
      end

      def edge_not_found_error(event)
        Cuprum::Error.new(message: "Edge not found: #{event.target}")
      end

      def find_edge(event:, node:)
        node.edges.find { |edge| edge_matches?(edge:, event:) }
      end

      def process(event:, state:)
        node = state.get('node')
        edge = find_edge(event:, node:)

        return failure(edge_not_found_error(event)) unless edge

        state.set('node', edge.target)

        notify(description: "You are in #{edge.target.short_desc}.")

        success
      end
    end

    class Look < Ephesus::Core::Command
      Event = Ephesus::Core::Message.define(:actor, :target)

      # Notification types:
      # - look (around): node -> full_description
      #     target_type: :node, target: 'hollow_town.town_square'
      # - look (direction): edge -> description
      #     target_type: :edge, target: 'hollow_town.town_square.east'
      # - look at (edge): edge -> description
      #     target_type: :edge, target: 'hollow_town.town_square.'
      # - look at (npc): npc -> description
      # - look at (interactible) interactible -> description
      Notification =
        Ephesus::Core::Messages::Notification
        .define(:area, :node, :target, :target_type)

      private

      def each_interactible(node)
        return enum_for(:each_interactible, node) unless block_given?

        node.edges.each { |edge| yield [edge, edge.label] }
      end

      def failure_message(target)
        "You don't see #{target}."
      end

      def find_interactible(node, target)
        each_interactible(node).each do |interactible, identifier|
          return interactible if identifier == target
        end

        nil
      end

      def notify_node(node:)
        notify(
          area:        node.area.slug,
          node:        node.slug,
          target:      nil,
          target_type: :node
        )
      end

      def process(event:, state:)
        node   = state.get('node')
        actor  = event.actor
        target = event.target

        if target.nil?
          notify_node(node:)
        else
          interactible = find_interactible(node, target)

          if interactible
            notify(actor:, text: interactible.full_desc)
          else
            notify(actor:, text: failure_message(target))
          end
        end

        success
      end
    end
  end

  module Formats
    module PlainText
      class FormatInput < Ephesus::Core::Formats::Commands::FormatInput
        private

        def parse_input(input_event)
          actor = input_event.connection.actor
          text  = input_event.text

          if text.start_with?('look around')
            Exploration::Commands::Look::Event.new(actor:, target: nil)
          else
            raise 'oh no'
          end
        end

        def process(input_event)
          event = step { parse_input(input_event) }

          step { check_if_event_handled(event) }

          event
        end
      end

      class FormatOutput < Ephesus::Core::Formats::Commands::FormatOutput
        def initialize(**)
          super

          @messages = YAML.safe_load(File.read('exploration.yml'))
        end

        attr_reader :messages

        private

        def fetch_description(*path, &default)
          messages
            .dig('exploration', *path)
            &.then { |message| return message }

          "Message not found: exploration.#{path.join(', ')}"
        end

        def handle_look(message)
          case message.target_type
          when :node
            if message.current_actor == message.original_actor
              fetch_description(
                'nodes',
                message.area,
                message.node,
                'full_desc'
              )
            else
              "#{message.original_actor.name} looked around."
            end
          else
            raise 'oh no'
          end
        end

        def normalize_description(text)
          text.split(/\n{2,}/).map { |str| str.gsub("\n",' ') }.join("\n\n")
        end

        def process(notification)
          text =
            case notification
            when Exploration::Commands::Look::Notification
              handle_look(notification)
            else
              raise "Unhandled notification #{notification.inspect}"
            end

          text = normalize_description(text)

          Ephesus::Core::Formats::PlainText::OutputEvent.new(
            original_type: notification.type,
            text:
          )
        end
      end

      class Formatter
        include Ephesus::Core::Formats::Formatter
        include Ephesus::Core::Messages::Typing

        TYPE = Ephesus::Core::Formats::PlainText.type

        private

        def input_formatter_for(**)
          Exploration::Formats::PlainText::FormatInput.new(**)
        end

        def output_formatter_for(**)
          Exploration::Formats::PlainText::FormatOutput.new(**)
        end
      end
    end
  end

  class Engine < Ephesus::Core::Engine
    private

    def build_actor(connection) = Exploration::Character.new(connection:)
  end

  class Scene < Ephesus::Core::Scene
    handle_event Exploration::Commands::Go
    handle_event Exploration::Commands::Look
  end

  def self.generate_slug(name)
    SleepingKingStudios::Tools::Toolbelt
      .instance
      .string_tools
      .underscore(name)
      .tr(' ', '_')
  end

  AREAS =
    [
      { name: 'Hollow Town' }
    ]
    .map  { |attributes| Exploration::Area.new(**attributes) }
    .each { |entity| entity.id = SecureRandom.uuid }
    .each { |entity| entity.slug = generate_slug(entity.name) }
    .to_h { |entity| [entity.slug, entity] }
    .freeze

  NODES =
    [
      { name: 'Town Square' },
      { name: 'The Old Church' }
    ]
    .map  { |attributes| Exploration::Node.new(**attributes) }
    .each { |entity| entity.id = SecureRandom.uuid }
    .each { |entity| entity.slug = generate_slug(entity.name) }
    .each { |entity| entity.area = AREAS.fetch('hollow_town') }
    .to_h { |entity| [entity.slug, entity] }
    .freeze

  EDGES =
    [
      {
        source:    'town_square',
        target:    'the_old_church',
        direction: 'east',
        label:     'the old church'
      }
    ]
    .map do |attributes|
      attributes.merge(
        source: NODES.values.find { |node| node.slug == attributes[:source] },
        target: NODES.values.find { |node| node.slug == attributes[:target] }
      )
    end
    .map  { |attributes| Exploration::Edge.new(**attributes) }
    .each { |entity| entity.id = SecureRandom.uuid }
    .freeze
end
