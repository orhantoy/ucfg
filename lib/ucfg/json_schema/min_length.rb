# frozen_string_literal: true

require "ucfg/json_schema"

module Ucfg
  module JSONSchema
    class MinLength
      class << self
        def validate(instance, schema, path:)
          return unless schema.key?("minLength")

          unless schema["minLength"].is_a?(Integer) && schema["minLength"] >= 0
            return JSONSchema.schema_error(path, "minLength", "must be a non-negative integer")
          end

          return unless instance.is_a?(String)

          return if instance.length >= schema["minLength"]

          JSONSchema.result_with_validation_error("Property `#{path.join('.')}` must have at least #{schema['minLength']} characters (provided length #{instance.length})")
        end
      end
    end
  end
end
