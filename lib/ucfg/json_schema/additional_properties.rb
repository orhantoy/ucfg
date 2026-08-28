# frozen_string_literal: true

require "ucfg/json_schema/validator"

module Ucfg
  module JSONSchema
    class AdditionalProperties < Validator
      handles "additionalProperties"

      class << self
        def validate(instance, schema, path:, context:)
          return context unless schema.key?("additionalProperties")

          rule = schema["additionalProperties"]
          return context.add_schema_error(path, "additionalProperties", "must be a boolean or object") unless valid_rule?(rule)

          return context unless instance.is_a?(Hash)

          explicit_properties = schema["properties"].is_a?(Hash) ? schema["properties"] : {}
          compiled_patterns = compile_patterns(schema, path: path)
          return context unless compiled_patterns

          reject_unsupported(instance, explicit_properties, compiled_patterns, path: path, context: context) if rule == false
          validate_additional(instance, rule, explicit_properties, compiled_patterns, path: path, context: context) if rule.is_a?(Hash)
          context
        end

        private

        def valid_rule?(rule)
          [true, false].include?(rule) || rule.is_a?(Hash)
        end

        def compile_patterns(schema, path:)
          pattern_properties = schema["patternProperties"].is_a?(Hash) ? schema["patternProperties"] : {}
          pattern_context = ValidationContext.new
          patterns = JSONSchema.compile_pattern_properties(
            pattern_properties,
            path: path + ["patternProperties"],
            context: pattern_context,
          )
          patterns if pattern_context.valid?
        end

        def reject_unsupported(instance, explicit, patterns, path:, context:)
          instance.each_key do |key|
            next unless additional_property?(key, explicit, patterns)

            context.add_error(
              "Property `#{(path + [key]).join('.')}` is not supported",
              path: path + [key],
              keyword: "additionalProperties",
            )
          end
        end

        def validate_additional(instance, rule, explicit, patterns, path:, context:)
          instance.each_key do |key|
            next unless additional_property?(key, explicit, patterns)

            JSONSchema.validate_recursively(instance.fetch(key), rule, path: path + [key], context: context)
          end
        end

        def additional_property?(key, explicit, patterns)
          !explicit.key?(key) && patterns.none? { |regex, _| regex.match?(key.to_s) }
        end
      end
    end
  end
end
