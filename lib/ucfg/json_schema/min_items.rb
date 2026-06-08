# frozen_string_literal: true

require "ucfg/json_schema"

module Ucfg
  module JSONSchema
    class MinItems
      class << self
        def validate(instance, schema, path:)
          return unless schema.key?("minItems")

          unless schema["minItems"].is_a?(Integer) && schema["minItems"] >= 0
            return JSONSchema.schema_error(path, "minItems", "must be a non-negative integer")
          end

          return unless instance.is_a?(Array)

          return if instance.length >= schema["minItems"]

          JSONSchema.result_with_validation_error("Property `#{path.join('.')}` must contain at least #{schema['minItems']} items (provided #{instance.length})")
        end
      end
    end
  end
end
