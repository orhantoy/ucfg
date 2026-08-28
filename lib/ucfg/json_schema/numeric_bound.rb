# frozen_string_literal: true

require "ucfg/json_schema/validator"

module Ucfg
  module JSONSchema
    class NumericBound < Validator
      class << self
        def configure(definitions)
          @definitions = definitions.each(&:freeze).freeze
          handles(*definitions.map(&:first))
        end

        def validate(instance, schema, path:, context:)
          valid_schema = validate_keywords(schema, path: path, context: context)
          return context unless valid_schema

          return context unless instance.is_a?(Numeric)
          return context if handled_by_legacy_range?(schema)

          @definitions.each do |keyword, operator, text|
            next unless schema.key?(keyword)
            next if schema[keyword].public_send(operator, instance)

            context.add_error(
              "#{subject(path)} must be #{text} #{schema[keyword]} (provided #{instance})",
              path: path,
              keyword: keyword,
            )
          end
          context
        end

        private

        def validate_keywords(schema, path:, context:)
          valid = true
          @definitions.each do |keyword, _, _|
            next unless schema.key?(keyword)
            next if schema[keyword].is_a?(Numeric)

            context.add_schema_error(path, keyword, "must be a number")
            valid = false
          end
          valid
        end

        def handled_by_legacy_range?(schema)
          schema.key?("min") &&
            schema.key?("max") &&
            schema["min"].is_a?(Numeric) &&
            schema["max"].is_a?(Numeric) &&
            !schema.key?("minimum") &&
            !schema.key?("maximum") &&
            !schema.key?("exclusiveMinimum") &&
            !schema.key?("exclusiveMaximum")
        end
      end
    end
  end
end
