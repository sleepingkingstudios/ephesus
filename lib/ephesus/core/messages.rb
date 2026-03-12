# frozen_string_literal: true

require 'ephesus/core'

module Ephesus::Core
  # Namespace for functionality defining and publishing messages.
  module Messages
    autoload :Definitions,  'ephesus/core/messages/definitions'
    autoload :Subscription, 'ephesus/core/messages/subscription'
    autoload :Typing,       'ephesus/core/messages/typing'
  end
end
