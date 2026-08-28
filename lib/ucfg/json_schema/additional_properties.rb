# frozen_string_literal: true

require "ucfg/json_schema/validator"

module Ucfg
  module JSONSchema
    class AdditionalProperties < Validator
      handles "additionalProperties"

      class << self
        def validate(instance, schema, path:, context:)
          return context unless schema.key?("additionalProperties")

          unless [true, false].include?(schema["additionalProperties"]) || schema["additionalProperties"].is_a?(Hash)
            return context.add_schema_error(path, "additionalProperties", "must be a boolean or object")
          end

          return context unless instance.is_a?(Hash)

          explicit_properties = schema["properties"].is_a?(Hash) ? schema["properties"] : {}
          pattern_properties = schema["patternProperties"].is_a?(Hash) ? schema["patternProperties"] : {}
          pattern_context = ValidationContext.new
          compiled_patterns = JSONSchema.compile_pattern_properties(
            pattern_properties,
            path: path + ["patternProperties"],
            context: pattern_context,
          )
          return context unless pattern_context.valid?

          key_matches_pattern = ->(key) { compiled_patterns.any? { |regex, _| regex.match?(key.to_s) } }

          if schema["additionalProperties"] == false
            instance.each_key do |key|
              next if explicit_properties.key?(key)
              next if key_matches_pattern.call(key)

              context.add_error(
                "Property `#{(path + [key]).join('.')}` is not supported",
                path: path + [key],
                keyword: "additionalProperties",
              )
            end
          elsif schema["additionalProperties"].is_a?(Hash)
            instance.each_key do |key|
              next if explicit_properties.key?(key)
              next if key_matches_pattern.call(key)

              JSONSchema.validate_recursively(
                instance.fetch(key),
                schema["additionalProperties"],
                path: path + [key],
                context: context,
              )
            end
          end
          context
        end
      end
    end
  end
end
