# frozen_string_literal: true

require "ucfg/json_schema/validator"

module Ucfg
  module JSONSchema
    class MinMax < Validator
      handles "min", "max"

      class << self
        def validate(instance, schema, path:, context:)
          return context unless exact_legacy_range?(schema)
          return context unless instance.is_a?(Numeric)

          return context if instance.between?(schema["min"], schema["max"])

          context.add_error(
            "#{subject(path)} must be between #{schema['min']} and #{schema['max']} (provided #{instance})",
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
