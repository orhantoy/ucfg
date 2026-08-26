# frozen_string_literal: true

require "ucfg/json_schema"

module Ucfg
  module JSONSchema
    class MinMax
      class << self
        def validate(instance, schema, path:)
          return unless exact_legacy_range?(schema)
          return unless instance.is_a?(Numeric)

          return if schema["min"] <= instance && schema["max"] >= instance

          JSONSchema.result_with_validation_error(
            "Property `#{path.join('.')}` must be between #{schema['min']} and #{schema['max']} (provided #{instance})",
            path: path,
            keyword: "min/max",
          )
        end

        def exact_legacy_range?(schema)
          schema.key?("min") &&
            schema.key?("max") &&
            schema["min"].is_a?(Numeric) &&
            schema["max"].is_a?(Numeric) &&
            !schema.key?("minimum") &&
            !schema.key?("maximum") &&
            !schema.key?("exclusiveMinimum") &&
            !schema.key?("exclusiveMaximum")
        end
      end
    end
  end
end
