# frozen_string_literal: true

require "ucfg/json_schema"

module Ucfg
  module JSONSchema
    class Enum
      class << self
        def validate(instance, schema, path:)
          return unless schema.key?("enum")
          return unless schema["enum"].is_a?(Array)
          return if schema["enum"].include?(instance)

          JSONSchema.result_with_validation_error("Property `#{path.join('.')}` contains an unsupported value (provided `#{instance}`)")
        end
      end
    end
  end
end
