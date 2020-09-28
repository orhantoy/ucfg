# frozen_string_literal: true

require "ucfg/json_schema"

module Ucfg
  module JSONSchema
    class Required
      class << self
        def validate(instance, schema, path:)
          return unless schema.key?("required")
          return unless schema["required"].is_a?(Array)
          return unless instance.is_a?(Hash)

          schema["required"].reduce(JSONSchema.empty_result) do |memo, required_key|
            result = JSONSchema.result_with_validation_error("Required property `#{(path + [required_key]).join('.')}` is missing") unless instance.key?(required_key)
            JSONSchema.combine_results(memo, result)
          end
        end
      end
    end
  end
end
