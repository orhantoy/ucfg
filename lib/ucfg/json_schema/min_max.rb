# frozen_string_literal: true

require "ucfg/json_schema"

module Ucfg
  module JSONSchema
    class MinMax
      class << self
        def validate(instance, schema, path:)
          return unless schema.key?("min")
          return unless schema.key?("max")
          return unless schema["min"].is_a?(Numeric)
          return unless schema["max"].is_a?(Numeric)
          return unless instance.is_a?(Numeric)

          return if schema["min"] <= instance && schema["max"] >= instance

          JSONSchema.result_with_validation_error("Property `#{path.join('.')}` must be between #{schema['min']} and #{schema['max']} (provided #{instance})")
        end
      end
    end
  end
end
