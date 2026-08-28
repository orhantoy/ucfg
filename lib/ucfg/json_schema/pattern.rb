# frozen_string_literal: true

require "ucfg/json_schema/validation"

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

          JSONSchema.result_with_validation_error(
            "Property `#{path.join('.')}` must match pattern `#{schema['pattern']}` (provided `#{instance}`)",
            path: path,
            keyword: "pattern",
          )
        rescue RegexpError => e
          JSONSchema.result_with_validation_error(
            "Property `#{path.join('.')}` has invalid pattern `#{schema['pattern']}` in schema (#{e.message})",
            path: path,
            keyword: "pattern",
            type: :schema,
          )
        end
      end
    end
  end
end
