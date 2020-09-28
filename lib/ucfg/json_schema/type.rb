# frozen_string_literal: true

require "ucfg/json_schema"

module Ucfg
  module JSONSchema
    class Type
      class << self
        def validate(instance, schema, path:)
          return unless schema.key?("type")

          return if schema["type"].is_a?(String) && schema["type"] == value_type(instance)
          return if schema["type"].is_a?(Array) && schema["type"].include?(value_type(instance))

          JSONSchema.result_with_validation_error("Property `#{path.join('.')}` must be of type #{type_to_sentence(schema['type'])} (#{value_type_error(instance)})")
        end

        def type_to_sentence(type)
          if type.is_a?(String)
            "`#{type}`"
          elsif type.is_a?(Array)
            type.map { |t| "`#{t}`" }.join(" or ")
          end
        end

        def value_type_error(value)
          if value.nil?
            "provided `null`"
          else
            "provided value `#{value}` of type `#{value_type(value)}`"
          end
        end

        def value_type(value)
          case value
          when String
            "string"
          when true, false
            "boolean"
          when nil
            "null"
          when Numeric
            "number"
          when Array
            "array"
          when Hash
            "object"
          end
        end
      end
    end
  end
end
