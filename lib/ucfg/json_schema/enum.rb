# frozen_string_literal: true

require "ucfg/json_schema/validator"

module Ucfg
  module JSONSchema
    class Enum < Validator
      handles "enum"

      class << self
        def validate(instance, schema, path:, context:)
          return context unless schema.key?("enum")

          return context.add_schema_error(path, "enum", "must be an array") unless schema["enum"].is_a?(Array)

          return context if schema["enum"].include?(instance)

          context.add_error(
            "#{subject(path)} contains an unsupported value (provided `#{instance}`)",
            path: path,
            keyword: "enum",
          )
        end
      end
    end
  end
end
