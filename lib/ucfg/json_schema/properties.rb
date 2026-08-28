# frozen_string_literal: true

require "ucfg/json_schema/validator"

module Ucfg
  module JSONSchema
    class Properties < Validator
      handles "properties"

      class << self
        def validate(instance, schema, path:)
          return unless schema.key?("properties")

          unless schema["properties"].is_a?(Hash)
            return JSONSchema.schema_error(path, "properties", "must be an object")
          end

          schema_errors = property_schema_errors(schema["properties"], path: path)
          return schema_errors unless schema_errors.valid?

          schema["properties"].reduce(JSONSchema.empty_result) do |memo, (key, sub_schema)|
            result = JSONSchema.validate_recursively(instance[key], sub_schema, path: path + [key]) if instance.is_a?(Hash) && instance.key?(key)
            JSONSchema.combine_results(memo, result)
          end
        end

        private

        def property_schema_errors(properties, path:)
          properties.reduce(JSONSchema.empty_result) do |memo, (key, sub_schema)|
            result = JSONSchema.schema_error(path + ["properties"], key, "must be an object") unless sub_schema.is_a?(Hash)
            JSONSchema.combine_results(memo, result)
          end
        end
      end
    end
  end
end
