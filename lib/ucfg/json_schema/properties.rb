# frozen_string_literal: true

require "ucfg/json_schema"

module Ucfg
  module JSONSchema
    class Properties
      class << self
        def validate(instance, schema, path:)
          return unless schema.key?("properties")
          return unless schema["properties"].is_a?(Hash)
          return unless instance.is_a?(Hash)

          schema["properties"].reduce(JSONSchema.empty_result) do |memo, (key, sub_schema)|
            result = JSONSchema.validate_recursively(instance[key], sub_schema, path: path + [key]) if instance.key?(key)
            JSONSchema.combine_results(memo, result)
          end
        end
      end
    end
  end
end
