# frozen_string_literal: true

require "ucfg/json_schema/validator"

module Ucfg
  module JSONSchema
    class Const < Validator
      handles "const"

      class << self
        def validate(instance, schema, path:, context:)
          return context unless schema.key?("const")
          return context if schema["const"] == instance

          context.add_error(
            "#{subject(path)} must have value `#{schema['const']}` (provided `#{instance}`)",
            path: path,
            keyword: "const",
          )
        end
      end
    end
  end
end
