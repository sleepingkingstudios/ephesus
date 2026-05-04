# frozen_string_literal: true

require 'async'
require 'async/semaphore'
require 'mustermann'

require 'examples/chat'

RSpec.describe Examples::Chat do
  subject(:engine) do
    described_class::Engine
      .new
      .extend(Ephesus::Core::Engines::AsynchronousEngine)
  end

  let(:scene) { engine.get_scene(Examples::Chat::Scenes::ChatRoom) }
  let(:formats) do
    [
      Examples::Chat::Formats::PlainText::Formatter
    ]
      .to_h { |format| [format.type, format] }
  end
  let(:aina) do
    Ephesus::Core::Connection.new(
      data:    { name: 'Aina Sahalin' },
      format:  Ephesus::Core::Formats::PlainText.type,
      formats:
    )
  end
  let(:shiro) do
    Ephesus::Core::Connection.new(
      format:  Ephesus::Core::Formats::PlainText.type,
      formats:
    )
  end

  define_method :input_message do |text|
    Ephesus::Core::Formats::PlainText::InputMessage.new(text:)
  end

  xspecify do
    Async do
      engine.start

      aina.add_subscription(aina, channel: :output) { |message| puts message.text }

      puts "\n"

      engine.add_connection(aina)
      engine.add_connection(shiro)

      aina.handle_input(input_message('Greetings, programs!'))
      shiro.handle_input(input_message('Shiro Amada'))
      shiro.handle_input(input_message('Hello, world!'))

      engine.stop
    end
  end

  pending
end
