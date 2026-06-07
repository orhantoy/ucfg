# frozen_string_literal: true

require "ucfg/json_schema"

module Ucfg
  module JSONSchema
    class AnyOf
      class << self
        def validate(instance, schema, path:)
          return unless schema.key?("anyOf")
          return unless schema["anyOf"].is_a?(Array)

          return if matching_subschema_count(instance, schema["anyOf"], path: path) > 0

          JSONSchema.result_with_validation_error("Property `#{path.join('.')}` must match at least one schema in `anyOf`")
        end

        private

        def matching_subschema_count(instance, subschemas, path:)
          subschemas.count do |subschema|
            result = JSONSchema.validate_recursively(instance, subschema, path: path)
            result.fetch(:validation_errors).empty?
          end
        end
      end
    end
  end
end
