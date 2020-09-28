# frozen_string_literal: true

require "ucfg/json_schema"

module Ucfg
  module JSONSchema
    class Const
      class << self
        def validate(instance, schema, path:)
          return unless schema.key?("const")
          return if schema["const"] == instance

          JSONSchema.result_with_validation_error("Property `#{path.join('.')}` must have value `#{schema['const']}` (provided `#{instance}`)")
        end
      end
    end
  end
end
