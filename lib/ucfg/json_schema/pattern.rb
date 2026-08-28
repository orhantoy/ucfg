# frozen_string_literal: true

require "ucfg/json_schema/validator"

module Ucfg
  module JSONSchema
    class Pattern < Validator
      handles "pattern"

      class << self
        def validate(instance, schema, path:, context:)
          return context unless schema.key?("pattern")

          return context.add_schema_error(path, "pattern", "must be a string") unless schema["pattern"].is_a?(String)

          regexp = Regexp.new(schema["pattern"])
          return context unless instance.is_a?(String)
          return context if instance.match?(regexp)

          context.add_error(
            "Property `#{path.join('.')}` must match pattern `#{schema['pattern']}` (provided `#{instance}`)",
            path: path,
            keyword: "pattern",
          )
        rescue RegexpError => e
          context.add_error(
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
