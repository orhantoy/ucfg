# frozen_string_literal: true

require "ucfg/json_schema"

module Ucfg
  module JSONSchema
    class AdditionalProperties
      class << self
        def validate(instance, schema, path:)
          return unless schema.key?("additionalProperties")
          return unless instance.is_a?(Hash)

          if schema["additionalProperties"] == false
            return unless schema.key?("properties")
            return unless schema["properties"].is_a?(Hash)

            instance.reduce(JSONSchema.empty_result) do |memo, (key, _)|
              result = JSONSchema.result_with_validation_error("Property `#{(path + [key]).join('.')}` is not supported") unless schema["properties"].key?(key)
              JSONSchema.combine_results(memo, result)
            end
          elsif schema["additionalProperties"].is_a?(Hash)
            instance.reduce(JSONSchema.empty_result) do |memo, (key, _)|
              result =
                if schema.key?("properties") && schema["properties"].is_a?(Hash) && !schema["properties"].key?(key) || !schema.key?("properties")
                  JSONSchema.validate_recursively(instance.fetch(key), schema["additionalProperties"], path: path + [key])
                end
              JSONSchema.combine_results(memo, result)
            end
          end
        end
      end
    end
  end
end
