# frozen_string_literal: true

require "ucfg/json_schema"

module Ucfg
  module JSONSchema
    class AdditionalProperties
      class << self
        def validate(instance, schema, path:)
          return unless schema.key?("additionalProperties")
          return unless instance.is_a?(Hash)

          explicit_properties = schema["properties"].is_a?(Hash) ? schema["properties"] : {}
          pattern_properties = schema["patternProperties"].is_a?(Hash) ? schema["patternProperties"] : {}
          compiled_patterns, _ = JSONSchema.compile_pattern_properties(pattern_properties, path: path + ["patternProperties"])
          key_matches_pattern = ->(key) { compiled_patterns.any? { |regex, _| regex.match?(key.to_s) } }

          if schema["additionalProperties"] == false
            instance.reduce(JSONSchema.empty_result) do |memo, (key, _)|
              next memo if explicit_properties.key?(key)
              next memo if key_matches_pattern.call(key)

              result = JSONSchema.result_with_validation_error("Property `#{(path + [key]).join('.')}` is not supported")
              JSONSchema.combine_results(memo, result)
            end
          elsif schema["additionalProperties"].is_a?(Hash)
            instance.reduce(JSONSchema.empty_result) do |memo, (key, _)|
              next memo if explicit_properties.key?(key)
              next memo if key_matches_pattern.call(key)

              result = JSONSchema.validate_recursively(instance.fetch(key), schema["additionalProperties"], path: path + [key])
              JSONSchema.combine_results(memo, result)
            end
          end
        end
      end
    end
  end
end
