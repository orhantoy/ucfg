# frozen_string_literal: true

require "ucfg/json_schema/validator"

module Ucfg
  module JSONSchema
    class Properties < Validator
      handles "properties"

      class << self
        def validate(instance, schema, path:, context:)
          return context unless schema.key?("properties")

          unless schema["properties"].is_a?(Hash)
            return context.add_schema_error(path, "properties", "must be an object")
          end

          valid_schemas = validate_property_schemas(schema["properties"], path: path, context: context)
          return context unless valid_schemas

          schema["properties"].each do |key, sub_schema|
            next unless instance.is_a?(Hash) && instance.key?(key)

            JSONSchema.validate_recursively(instance[key], sub_schema, path: path + [key], context: context)
          end
          context
        end

        private

        def validate_property_schemas(properties, path:, context:)
          valid = true
          properties.each do |key, sub_schema|
            next if sub_schema.is_a?(Hash)

            context.add_schema_error(path + ["properties"], key, "must be an object")
            valid = false
          end
          valid
        end
      end
    end
  end
end
