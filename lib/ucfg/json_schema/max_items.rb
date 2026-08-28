# frozen_string_literal: true

require "ucfg/json_schema/validation"

module Ucfg
  module JSONSchema
    class MaxItems
      class << self
        def validate(instance, schema, path:)
          return unless schema.key?("maxItems")

          unless schema["maxItems"].is_a?(Integer) && schema["maxItems"] >= 0
            return JSONSchema.schema_error(path, "maxItems", "must be a non-negative integer")
          end

          return unless instance.is_a?(Array)

          return if instance.length <= schema["maxItems"]

          JSONSchema.result_with_validation_error(
            "Property `#{path.join('.')}` must contain at most #{schema['maxItems']} items (provided #{instance.length})",
            path: path,
            keyword: "maxItems",
          )
        end
      end
    end
  end
end
