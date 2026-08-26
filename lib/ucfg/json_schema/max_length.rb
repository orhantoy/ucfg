# frozen_string_literal: true

require "ucfg/json_schema"

module Ucfg
  module JSONSchema
    class MaxLength
      class << self
        def validate(instance, schema, path:)
          return unless schema.key?("maxLength")

          unless schema["maxLength"].is_a?(Integer) && schema["maxLength"] >= 0
            return JSONSchema.schema_error(path, "maxLength", "must be a non-negative integer")
          end

          return unless instance.is_a?(String)

          return if instance.length <= schema["maxLength"]

          JSONSchema.result_with_validation_error(
            "Property `#{path.join('.')}` must have at most #{schema['maxLength']} characters (provided length #{instance.length})",
            path: path,
            keyword: "maxLength",
          )
        end
      end
    end
  end
end
