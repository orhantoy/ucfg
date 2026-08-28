# frozen_string_literal: true

require "ucfg/json_schema/validation"

module Ucfg
  module JSONSchema
    class AllOf
      class << self
        def validate(instance, schema, path:)
          return unless schema.key?("allOf")

          unless schema["allOf"].is_a?(Array)
            return JSONSchema.schema_error(path, "allOf", "must be an array of schemas")
          end

          schema["allOf"].each_with_index.reduce(JSONSchema.empty_result) do |memo, (subschema, index)|
            result =
              if subschema.is_a?(Hash)
                JSONSchema.validate_recursively(instance, subschema, path: path)
              else
                JSONSchema.schema_error(path + ["allOf"], index, "must be an object")
              end
            JSONSchema.combine_results(memo, result)
          end
        end
      end
    end
  end
end
