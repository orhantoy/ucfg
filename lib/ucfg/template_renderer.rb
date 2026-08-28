# frozen_string_literal: true

require "erb"
require "ucfg/error"
require "ucfg/env_expander"
require "ucfg/source_coercion"

module Ucfg
  module TemplateRenderer
    class << self
      def render(source, erb: false, env: false)
        template = SourceCoercion.to_string(source, label: "Template")
        raise Error, "ERB and environment expansion cannot be enabled together" if erb && env

        return EnvExpander.expand_source(template) if env
        return template unless erb

        ERB.new(template).result
      rescue SyntaxError => e
        raise Error, "Invalid ERB syntax: #{e.message.lines.first&.strip || e.message}"
      end
    end
  end
end
