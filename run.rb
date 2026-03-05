# frozen_string_literal: true

require 'observer'
require 'securerandom'

Bundler.require(:default, :development)

require 'ephesus/core'
require 'ephesus/core/command'

module Ephesus::Core
  class Scene
    class << self
      def handle_event(typed, command = nil)
        command ||= typed if command_class?(typed)

        event_type = event_type_for(typed)

        handled_events[event_type] = command
      end

      # @todo: Should be inherited from parent.
      def handled_events = @handled_events ||= {}

      private

      def command_class?(value)
        value.is_a?(Class) && value < Ephesus::Core::Command
      end

      def event_type_for(typed)
        return typed if typed.is_a?(String)

        typed.type
      end
    end

    def initialize(state: {})
      @event_queue = []
      @event_stack = []
      @state       = build_state(state)
      @history     = []
    end

    attr_reader :history

    attr_reader :state

    private

    attr_reader :event_queue

    attr_reader :event_stack

    def build_state(state)
      Ephesus::Core::State.new(initial_state.merge(state))
    end

    def initial_state = { 'actors' => {} }

    private

    def event_handler_for(event)
      self.class.handled_events.fetch(event.type).new
    end

    def handle_event(event)
      history << event

      command = event_handler_for(event)
      result  = command.call(event:, state:)

      if result.success?
        @state, *side_effects = result.value
      else
        side_effects = result.value || []
      end

      side_effects
        &.each { |(type, *details)| handle_side_effect(type, *details) }
    end

    def handle_side_effect(type, *details)
      case type
      when :notify
        puts "Notify: #{details.first.inspect}"
      else
        raise "unhandled side effect: #{type.inspect}"
      end
    end
  end
end

module Ephesus
  class Actor
    def initialize
      @id = SecureRandom.uuid
    end

    attr_reader :id
  end

  class Scene
    include Observable

    def initialize(state: {})
      @event_queue = []
      @event_stack = []
      @state       = initial_state.merge(state)
    end

    attr_reader :state

    def call
      event = @event_queue.shift

      return unless event

      handle_event(event)

      while !@event_stack.empty?
        handle_event(@event_stack.pop)
      end
    end

    def enqueue(event) = @event_queue.push(event)

    def push(event) = @event_stack.push(event)

    private

    def event_handler_for(event) = event_handlers.fetch(event.type)

    # @todo: Replace this with class-level DSL for registration:
    #
    # ```ruby
    # handle_event 'some.event', SomeCommand
    # ```
    def event_handlers = {}

    def handle_event(event)
      event_handler = event_handler_for(event)
      event_handler = event_handler.new if event_handler.is_a?(Class)

      # @todo: Pass a Scene proxy instead?
      result = event_handler.call(event:, scene: self)
      @state = result.value if result.success?

      result
    end

    def initial_state = {}

    def toolbelt = @toolbelt ||= SleepingKingStudios::Tools::Toolbelt.instance
  end
end

module Monsters
  Species = Data.define(:name, :hit_points, :techniques)

  Technique = Data.define(:name, :effects)

  TECHNIQUES = {
    rage:   [{ type: 'damage_monster', amount: 40 }],
    splash: []
  }.to_h { |name, effects| [name, Monsters::Technique.new(name:, effects:)] }

  SPECIES = {
    dragon: {
      hit_points: 50,
      techniques: %i[rage]
    },
    fish:   {
      hit_points: 10,
      techniques: %i[splash]
    }
  }.to_h { |name, data| [name, Monsters::Species.new(name:, **data)] }

  class Character < Ephesus::Actor
    def initialize(name:, monsters: [])
      super()

      @name     = name
      @monsters = monsters
    end

    attr_reader :name, :monsters
  end

  class Monster
    def initialize(name)
      @id         = SecureRandom.uuid
      @name       = name
      @species    = SPECIES.fetch(name)
      @hit_points = species.hit_points
      @techniques = species.techniques.to_h do |technique_name|
        [technique_name, TECHNIQUES.fetch(technique_name)]
      end
    end

    attr_reader \
      :id,
      :name,
      :species,
      :techniques

    attr_accessor :hit_points
  end

  # class Battle < Ephesus::Scene
  #   class AddMonsterCommand < Ephesus::Command
  #     private

  #     def extra_monster_error
  #       message = "#{event.actor.name} already has a monster out!"

  #       Cuprum::Error.new(message:)
  #     end

  #     def process(event:, scene:)
  #       super

  #       monsters = (state.fetch(:monsters)[event.actor.id] ||= [])

  #       return failure(extra_monster_error) if monsters.one?

  #       puts "#{event.actor.name} chooses #{event.data.fetch(:monster).name}!"

  #       monsters << event.data.fetch(:monster)

  #       state
  #     end
  #   end

  #   class AddActionCommand < Ephesus::Command
  #     private

  #     def extra_action_error
  #       message = "#{event.actor.name} already has a command queued!"

  #       Cuprum::Error.new(message:)
  #     end

  #     def process(event:, scene:)
  #       super

  #       actions  = (state.fetch(:actions)[event.actor.id]  ||= [])
  #       monsters = (state.fetch(:monsters)[event.actor.id] ||= [])

  #       return failure(extra_action_error) if actions.count >= monsters.count

  #       actions << event.data.fetch(:action)

  #       state
  #     end
  #   end

  #   class BattleActionCommand < Ephesus::Command
  #     private

  #     def process(event:, scene:)
  #       super

  #       action    = event.data[:action]
  #       monster   = state.dig(:monsters, event.actor.id).first
  #       technique = monster.techniques[action]

  #       puts "#{monster.name} uses #{technique.name}!"

  #       technique.effects.each do |effect|
  #         type  = effect[:type]
  #         data  = effect.except(:type)
  #         event = Ephesus::Events::ActorEvent.new(type:, actor: event.actor, data:)

  #         scene.push(event)
  #       end

  #       state
  #     end
  #   end

  #   class DamageMonsterCommand < Ephesus::Command
  #     private

  #     def process(event:, scene:)
  #       super

  #       actor_id, monsters =
  #         state.dig(:monsters).find { |actor_id, _| actor_id != event.actor.id }
  #       monster = monsters.first
  #       amount  = event.data[:amount]

  #       puts "#{monster.name} takes #{amount} damage!"

  #       if monster.hit_points > amount
  #         # @todo: Immutability!!!
  #         monster.hit_points -= amount
  #       else
  #         monster.hit_points = 0

  #         type  = 'knocked_out'
  #         data  = { actor_id:, monster_id: monster.id }
  #         event = Ephesus::Events::ActorEvent.new(type:, actor: event.actor, data:)

  #         scene.push(event)
  #       end

  #       state
  #     end
  #   end

  #   class KnockedOutCommand < Ephesus::Command
  #     TYPE = 'monsters.battle.knocked_out'

  #     Notification = Ephesus::Core::Event.define(:monster_name, type: TYPE)

  #     private

  #     def process(event:, scene:)
  #       super

  #       monsters =
  #         state
  #         .dig(:monsters, event.data[:actor_id])
  #       monster  =
  #         monsters.find { |monster| monster.id == event.data[:monster_id] }

  #       scene.changed
  #       scene.notify_observers(
  #         Notification.new(monster_name: monster.name)
  #       )

  #       monsters.delete(monster)

  #       state
  #     end
  #   end

  #   def initialize(**)
  #     super

  #     @running = false
  #   end

  #   def call
  #     result = super

  #     if ready?
  #       start_turn
  #     elsif running?
  #       @running = false unless has_monsters? && has_actions?
  #     else
  #       result
  #     end
  #   end

  #   def ready? = status == :ready

  #   def running? = @running

  #   def status
  #     return :running if running?

  #     return :waiting_for_monsters unless has_monsters?

  #     return :waiting_for_actions unless has_actions?

  #     :ready
  #   end

  #   private

  #   def actions = @state[:actions]

  #   def characters = @state[:characters]

  #   def event_handlers
  #     {
  #       # 'add_action'     => AddActionCommand,
  #       # 'add_monster'    => AddMonsterCommand,
  #       # 'battle_action'  => BattleActionCommand,
  #       # 'damage_monster' => DamageMonsterCommand,
  #       # 'knocked_out'    => KnockedOutCommand
  #     }
  #   end

  #   def has_actions?
  #     characters.all? do |character|
  #       !actions[character.id].nil?
  #         && !monsters[character.id].nil?
  #         && actions[character.id].length == monsters[character.id].length
  #     end
  #   end

  #   def has_monsters? = false

  #   def initial_state
  #     {
  #       actions:    {},
  #       characters: [],
  #       monsters:   {}
  #     }
  #   end

  #   def monsters = @state[:monsters]

  #   def order_actions
  #     flattened = actions.each.with_object([]) do |(actor_id, actions), memo|
  #       actions.each { |action| memo << [actor_id, action] }
  #     end
  #   end

  #   def start_turn
  #     @running = true

  #     order_actions.each do |(actor_id, action)|
  #       # @todo: Resolve other implicit details, e.g. targeted creature.
  #       actor = characters.find { |character| character.id == actor_id }
  #       event = Ephesus::Events::ActorEvent.new(type: 'battle_action', actor:, data: { action: })

  #       enqueue(event)
  #     end
  #   end
  # end

  # class SingleBattle < Battle
  #   private

  #   def has_monsters?
  #     characters.all? do |character|
  #       monsters[character.id].is_a?(Array) && !monsters[character.id].empty?
  #     end
  #   end
  # end
end

fisher =
  Monsters::Character.new(
    name:     'Fisher',
    monsters: [
      Monsters::Monster.new(:fish),
      Monsters::Monster.new(:fish),
      Monsters::Monster.new(:fish)
    ]
  )
dragon_tamer =
  Monsters::Character.new(
    name:     'Dragon Tamer',
    monsters: [
      Monsters::Monster.new(:dragon)
    ]
  )

# battle = Monsters::SingleBattle.new(state: { characters: [dragon_tamer, fisher] })
# events = [
#   Ephesus::Events::ActorEvent.new(type: 'add_monster', actor: fisher, data: { monster: fisher.monsters.first }),
#   Ephesus::Events::ActorEvent.new(type: 'add_action',  actor: fisher, data: { action: :splash }),
#   Ephesus::Events::ActorEvent.new(type: 'add_monster', actor: dragon_tamer, data: { monster: dragon_tamer.monsters.first }),
#   Ephesus::Events::ActorEvent.new(type: 'add_action',  actor: dragon_tamer, data: { action: :rage })
# ]

# events.each { |event| battle.enqueue(event) }

# 20.times { battle.call }

module Monsters
  module Commands
    class ChooseMonster < Ephesus::Core::Command
      Event = Ephesus::Core::Event.define(:actor_id, :monster_id)

      Notification = Ephesus::Core::Event.define(:actor_name, :monster_name)

      private

      def find_actor
        state.fetch("actors.#{event.actor_id}.actor")
      end

      def find_monster(actor)
        actor.monsters.find { |monster| monster.id == event.monster_id }
      end

      def process(event:, state:)
        actor   = step { find_actor }
        monster = step { find_monster(actor) }
        @state  = state.set(
          "monsters.#{monster.id}",
          {
            'monster'  => monster,
            'owner_id' => actor.id
          }
        )

        notify(actor_name: actor.name, monster_name: monster.name)

        success
      end
    end
  end

  class BattleScene < Ephesus::Core::Scene
    handle_event Monsters::Commands::ChooseMonster
  end
end

state = {
  'actors'   => {
    dragon_tamer.id => { 'actor' => dragon_tamer },
    fisher.id       => { 'actor' => fisher }
  },
  'monsters' => {}
}
event = Monsters::Commands::ChooseMonster::Event.new(
  actor_id:   dragon_tamer.id,
  monster_id: dragon_tamer.monsters.first.id
)
scene = Monsters::BattleScene.new(state:)
scene.send :handle_event, event

# command = Monsters::Commands::ChooseMonster.new
# result  = command.call(event:, state:)

# state, *side_effects = result.value

byebug
self
