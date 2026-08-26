# frozen_string_literal: true

require "ucfg/json_schema"

module Ucfg
  module JSONSchema
    class Enum
      class << self
        def validate(instance, schema, path:)
          return unless schema.key?("enum")

          unless schema["enum"].is_a?(Array)
            return JSONSchema.schema_error(path, "enum", "must be an array")
          end

          return if schema["enum"].include?(instance)

          JSONSchema.result_with_validation_error(
            "Property `#{path.join('.')}` contains an unsupported value (provided `#{instance}`)",
            path: path,
            keyword: "enum",
          )
        end
      end
    end
  end
end
