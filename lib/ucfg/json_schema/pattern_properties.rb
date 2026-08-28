# frozen_string_literal: true

require "ucfg/json_schema/validator"

module Ucfg
  module JSONSchema
    class PatternProperties < Validator
      handles "patternProperties"

      class << self
        def validate(instance, schema, path:, context:)
          return context unless schema.key?("patternProperties")

          return context.add_schema_error(path, "patternProperties", "must be an object") unless schema["patternProperties"].is_a?(Hash)

          initial_error_count = context.error_count
          compiled_patterns = JSONSchema.compile_pattern_properties(
            schema["patternProperties"],
            path: path + ["patternProperties"],
            context: context,
          )
          return context if context.error_count > initial_error_count

          return context unless instance.is_a?(Hash)

          instance.each do |key, value|
            compiled_patterns.each do |regex, sub_schema|
              next unless regex.match?(key.to_s)

              JSONSchema.validate_recursively(value, sub_schema, path: path + [key], context: context)
            end
          end
          context
        end
      end
    end
  end
end
