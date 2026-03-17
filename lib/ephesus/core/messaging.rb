# frozen_string_literal: true

require 'ephesus/core'

module Ephesus::Core
  # Namespace for functionality publishing and subscribing to messages.
  module Messaging
    autoload :Publisher,    'ephesus/core/messaging/publisher'
    autoload :Subscriber,   'ephesus/core/messaging/subscriber'
    autoload :Subscription, 'ephesus/core/messaging/subscription'
  end
end
