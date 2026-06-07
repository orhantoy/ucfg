# frozen_string_literal: true

require "ucfg/json_schema"

module Ucfg
  module JSONSchema
    class OneOf
      class << self
        def validate(instance, schema, path:)
          return unless schema.key?("oneOf")
          return unless schema["oneOf"].is_a?(Array)

          matching_subschemas = matching_subschema_count(instance, schema["oneOf"], path: path)
          return if matching_subschemas == 1

          JSONSchema.result_with_validation_error("Property `#{path.join('.')}` must match exactly one schema in `oneOf` (matched #{matching_subschemas})")
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
