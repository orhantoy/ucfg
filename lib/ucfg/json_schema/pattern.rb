# frozen_string_literal: true

require "ucfg/json_schema"

module Ucfg
  module JSONSchema
    class Pattern
      class << self
        def validate(instance, schema, path:)
          return unless schema.key?("pattern")
          return unless instance.is_a?(String)
          return unless schema["pattern"].is_a?(String)

          return if instance.match?(Regexp.new(schema["pattern"]))

          JSONSchema.result_with_validation_error("Property `#{path.join('.')}` must match pattern `#{schema['pattern']}` (provided `#{instance}`)")
        end
      end
    end
  end
end
