# frozen_string_literal: true

require 'ephesus/core/formats/plain_text'

module Ephesus::Core::Formats::PlainText
  # Namespace for errors returned by failing plain text error commands.
  module Errors
    autoload :InvalidTemplate,
      'ephesus/core/formats/plain_text/errors/invalid_template'
    autoload :TemplateNotFound,
      'ephesus/core/formats/plain_text/errors/template_not_found'
  end
end
