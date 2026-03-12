# frozen_string_literal: true

require 'ephesus/core'

module Ephesus::Core
  # Namespace for functionality implementing messages.
  module Messages
    autoload :Definitions, 'ephesus/core/messages/definitions'
    autoload :Typing,      'ephesus/core/messages/typing'
  end
end
