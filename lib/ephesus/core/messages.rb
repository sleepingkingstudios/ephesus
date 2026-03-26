# frozen_string_literal: true

require 'ephesus/core'

module Ephesus::Core
  # Namespace for functionality implementing messages.
  module Messages
    autoload :Definitions,
      'ephesus/core/messages/definitions'
    autoload :ErrorNotification,
      'ephesus/core/messages/error_notification'
    autoload :LazyConnectionMessage,
      'ephesus/core/messages/lazy_connection_message'
    autoload :Notification,
      'ephesus/core/messages/notification'
    autoload :Typing,
      'ephesus/core/messages/typing'
  end
end
