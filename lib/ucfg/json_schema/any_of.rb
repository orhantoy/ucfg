# frozen_string_literal: true

require "ucfg/json_schema/validation"

module Ucfg
  module JSONSchema
    class AnyOf
      class << self
        def validate(instance, schema, path:)
          return unless schema.key?("anyOf")

          unless schema["anyOf"].is_a?(Array)
            return JSONSchema.schema_error(path, "anyOf", "must be an array of schemas")
          end

          schema_errors = invalid_subschema_errors(schema["anyOf"], path: path)
          return schema_errors unless schema_errors.valid?

          return if matching_subschema_count(instance, schema["anyOf"], path: path) > 0

          JSONSchema.result_with_validation_error(
            "Property `#{path.join('.')}` must match at least one schema in `anyOf`",
            path: path,
            keyword: "anyOf",
          )
        end

        private

        def invalid_subschema_errors(subschemas, path:)
          subschemas.each_with_index.reduce(JSONSchema.empty_result) do |memo, (subschema, index)|
            result = JSONSchema.schema_error(path + ["anyOf"], index, "must be an object") unless subschema.is_a?(Hash)
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
