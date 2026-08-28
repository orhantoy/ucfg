# frozen_string_literal: true

require "ucfg/json_schema/validator"

module Ucfg
  module JSONSchema
    class Required < Validator
      handles "required"

      class << self
        def validate(instance, schema, path:)
          return unless schema.key?("required")

          unless schema["required"].is_a?(Array)
            return JSONSchema.schema_error(path, "required", "must be an array of property names")
          end

          invalid_required = schema["required"].find { |required_key| !required_key.is_a?(String) }
          if invalid_required
            return JSONSchema.schema_error(path, "required", "must contain only property names")
          end

          return unless instance.is_a?(Hash)

          schema["required"].reduce(JSONSchema.empty_result) do |memo, required_key|
            unless instance.key?(required_key)
              result = JSONSchema.result_with_validation_error(
                "Required property `#{(path + [required_key]).join('.')}` is missing",
                path: path + [required_key],
                keyword: "required",
              )
            end
            JSONSchema.combine_results(memo, result)
          end
        end
      end
    end
  end
end
