# frozen_string_literal: true

require "ucfg/json_schema/validation"

module Ucfg
  module JSONSchema
    class PatternProperties
      class << self
        def validate(instance, schema, path:)
          return unless schema.key?("patternProperties")

          unless schema["patternProperties"].is_a?(Hash)
            return JSONSchema.schema_error(path, "patternProperties", "must be an object")
          end

          compiled_patterns, errors = JSONSchema.compile_pattern_properties(schema["patternProperties"], path: path + ["patternProperties"])
          return errors unless errors.valid?

          return unless instance.is_a?(Hash)

          result = instance.reduce(JSONSchema.empty_result) do |memo, (key, value)|
            key_result = compiled_patterns.reduce(JSONSchema.empty_result) do |key_memo, (regex, sub_schema)|
              next key_memo unless regex.match?(key.to_s)

              result = JSONSchema.validate_recursively(value, sub_schema, path: path + [key])
              JSONSchema.combine_results(key_memo, result)
            end
            JSONSchema.combine_results(memo, key_result)
          end

          JSONSchema.combine_results(errors, result)
        end
      end
    end
  end
end
