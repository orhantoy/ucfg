# frozen_string_literal: true

require "ucfg/json_schema"

module Ucfg
  module JSONSchema
    class AllOf
      class << self
        def validate(instance, schema, path:)
          return unless schema.key?("allOf")
          return unless schema["allOf"].is_a?(Array)

          schema["allOf"].reduce(JSONSchema.empty_result) do |memo, subschema|
            next memo unless subschema.is_a?(Hash)

            result = JSONSchema.validate_recursively(instance, subschema, path: path)
            JSONSchema.combine_results(memo, result)
          end
        end
      end
    end
  end
end
