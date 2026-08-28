# frozen_string_literal: true

require "ucfg/json_schema/validation"

module Ucfg
  module JSONSchema
    class OneOf
      class << self
        def validate(instance, schema, path:)
          return unless schema.key?("oneOf")

          unless schema["oneOf"].is_a?(Array)
            return JSONSchema.schema_error(path, "oneOf", "must be an array of schemas")
          end

          schema_errors = invalid_subschema_errors(schema["oneOf"], path: path)
          return schema_errors unless schema_errors.valid?

          matching_subschemas = matching_subschema_count(instance, schema["oneOf"], path: path)
          return if matching_subschemas == 1

          JSONSchema.result_with_validation_error(
            "Property `#{path.join('.')}` must match exactly one schema in `oneOf` (matched #{matching_subschemas})",
            path: path,
            keyword: "oneOf",
          )
        end

        private

        def invalid_subschema_errors(subschemas, path:)
          subschemas.each_with_index.reduce(JSONSchema.empty_result) do |memo, (subschema, index)|
            result = JSONSchema.schema_error(path + ["oneOf"], index, "must be an object") unless subschema.is_a?(Hash)
            JSONSchema.combine_results(memo, result)
          end
        end

        def matching_subschema_count(instance, subschemas, path:)
          subschemas.count do |subschema|
            result = JSONSchema.validate_recursively(instance, subschema, path: path)
            result.valid?
          end
        end
      end
    end
  end
end
