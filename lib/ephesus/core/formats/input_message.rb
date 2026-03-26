# frozen_string_literal: true

require 'ephesus/core/formats'
require 'ephesus/core/messages/lazy_connection_message'

module Ephesus::Core::Formats
  # Abstract message for passing data from a client to a connection.
  InputMessage = Ephesus::Core::Messages::LazyConnectionMessage.define(:format)
end
