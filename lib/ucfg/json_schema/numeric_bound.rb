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

        def validate(instance, schema, path:)
          schema_errors = invalid_keyword_errors(schema, path: path)
          return schema_errors unless schema_errors.valid?

          return unless instance.is_a?(Numeric)
          return if handled_by_legacy_range?(schema)

          errors = @definitions.each_with_object([]) do |(keyword, operator, text), memo|
            next unless schema.key?(keyword)
            next if schema[keyword].public_send(operator, instance)

            memo << ValidationError.new(
              message: "Property `#{path.join('.')}` must be #{text} #{schema[keyword]} (provided #{instance})",
              path: path,
              keyword: keyword,
            )
          end

          return if errors.empty?

          ValidationResult.new(error_details: errors)
        end

        private

        def invalid_keyword_errors(schema, path:)
          @definitions.each_with_object(JSONSchema.empty_result) do |(keyword, _, _), memo|
            next unless schema.key?(keyword)
            next if schema[keyword].is_a?(Numeric)

            memo.merge!(JSONSchema.schema_error(path, keyword, "must be a number"))
          end
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
