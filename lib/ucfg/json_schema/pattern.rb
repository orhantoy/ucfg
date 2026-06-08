# frozen_string_literal: true

require "ucfg/json_schema"

module Ucfg
  module JSONSchema
    class Pattern
      class << self
        def validate(instance, schema, path:)
          return unless schema.key?("pattern")

          unless schema["pattern"].is_a?(String)
            return JSONSchema.schema_error(path, "pattern", "must be a string")
          end

          regexp = Regexp.new(schema["pattern"])
          return unless instance.is_a?(String)
          return if instance.match?(regexp)

          JSONSchema.result_with_validation_error("Property `#{path.join('.')}` must match pattern `#{schema['pattern']}` (provided `#{instance}`)")
        rescue RegexpError => e
          JSONSchema.result_with_validation_error("Property `#{path.join('.')}` has invalid pattern `#{schema['pattern']}` in schema (#{e.message})")
        end
      end
    end
  end
end
