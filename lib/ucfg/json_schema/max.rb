# frozen_string_literal: true

require "ucfg/json_schema"

module Ucfg
  module JSONSchema
    class Max
      class << self
        def validate(instance, schema, path:)
          return if schema.key?("min")
          return unless schema.key?("max")
          return unless instance.is_a?(Numeric)
          return unless schema["max"].is_a?(Numeric)

          return if schema["max"] >= instance

          JSONSchema.result_with_validation_error("Property `#{path.join('.')}` must be less than or equal to #{schema['max']} (provided #{instance})")
        end
      end
    end
  end
end
