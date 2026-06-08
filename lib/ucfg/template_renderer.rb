# frozen_string_literal: true

require "erb"

module Ucfg
  module TemplateRenderer
    class << self
      def render(source, erb: false)
        template = normalize_source(source)
        return template unless erb

        ERB.new(template).result
      rescue SyntaxError => e
        raise Error, "Invalid ERB syntax: #{e.message.lines.first&.strip || e.message}"
      end

      private

      def normalize_source(source)
        return source.to_str if source.respond_to?(:to_str)

        raise Error, "Template source must be a string"
      end
    end
  end
end
