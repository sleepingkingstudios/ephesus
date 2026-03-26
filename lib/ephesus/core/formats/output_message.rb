# frozen_string_literal: true

require 'ephesus/core/formats'
require 'ephesus/core/message'

module Ephesus::Core::Formats
  # Abstract message for passing data from a connection to a client.
  OutputMessage = Ephesus::Core::Message.define(:format)
end
