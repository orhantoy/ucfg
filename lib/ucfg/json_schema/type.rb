# frozen_string_literal: true

require "ucfg/json_schema/validator"

module Ucfg
  module JSONSchema
    class Type < Validator
      handles "type"

      class << self
        def validate(instance, schema, path:, context:)
          return context unless schema.key?("type")

          type = schema["type"]
          return context.add_schema_error(path, "type", "must be a supported JSON Schema type or an array of supported types") unless valid_type_definition?(type)

          return context if Array(type).any? { |expected_type| matches_type?(instance, expected_type) }

          context.add_error(
            "Property `#{path.join('.')}` must be of type #{type_to_sentence(schema['type'])} (#{value_type_error(instance)})",
            path: path,
            keyword: "type",
          )
        end

        def type_to_sentence(type)
          if type.is_a?(String)
            "`#{type}`"
          elsif type.is_a?(Array)
            type.map { |t| "`#{t}`" }.join(" or ")
          end
        end

        def valid_type_definition?(type)
          if type.is_a?(String)
            valid_type?(type)
          elsif type.is_a?(Array)
            !type.empty? && type.all? { |item| item.is_a?(String) && valid_type?(item) }
          else
            false
          end
        end

        def valid_type?(type)
          %w[string boolean number integer null array object].include?(type)
        end

        def matches_type?(value, type)
          case type
          when "number"
            value.is_a?(Numeric)
          when "integer"
            value.is_a?(Integer)
          else
            value_type(value) == type
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
          when Integer
            "integer"
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
