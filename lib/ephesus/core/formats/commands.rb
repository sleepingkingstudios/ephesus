# frozen_string_literal: true

require 'ephesus/core/formats'

module Ephesus::Core::Formats
  # Namespace for commands implementing IO formatting.
  module Commands
    autoload :FormatInput,  'ephesus/core/formats/commands/format_input'
    autoload :FormatOutput, 'ephesus/core/formats/commands/format_output'
  end
end
