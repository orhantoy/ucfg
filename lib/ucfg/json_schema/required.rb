# frozen_string_literal: true

require "ucfg/json_schema/validator"

module Ucfg
  module JSONSchema
    class Required < Validator
      handles "required"

      class << self
        def validate(instance, schema, path:, context:)
          return context unless schema.key?("required")

          unless schema["required"].is_a?(Array)
            return context.add_schema_error(path, "required", "must be an array of property names")
          end

          invalid_required = schema["required"].find { |required_key| !required_key.is_a?(String) }
          if invalid_required
            return context.add_schema_error(path, "required", "must contain only property names")
          end

          return context unless instance.is_a?(Hash)

          schema["required"].each do |required_key|
            next if instance.key?(required_key)

            context.add_error(
              "Required property `#{(path + [required_key]).join('.')}` is missing",
              path: path + [required_key],
              keyword: "required",
            )
          end
          context
        end
      end
    end
  end
end
