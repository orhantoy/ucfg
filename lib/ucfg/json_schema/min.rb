# frozen_string_literal: true

require "ucfg/json_schema"

module Ucfg
  module JSONSchema
    class Min
      class << self
        def validate(instance, schema, path:)
          return if schema.key?("max")
          return unless schema.key?("min")
          return unless instance.is_a?(Numeric)
          return unless schema["min"].is_a?(Numeric)

          return if schema["min"] <= instance

          JSONSchema.result_with_validation_error("Property `#{path.join('.')}` must be greater than or equal to #{schema['min']} (provided #{instance})")
        end
      end
    end
  end
end
