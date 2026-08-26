# frozen_string_literal: true

require "ucfg/json_schema"

module Ucfg
  module JSONSchema
    class Min
      MIN_KEYWORDS = [
        ["min", :<=, "greater than or equal to"],
        ["minimum", :<=, "greater than or equal to"],
        ["exclusiveMinimum", :<, "greater than"],
      ].freeze

      class << self
        def validate(instance, schema, path:)
          schema_errors = invalid_keyword_errors(schema, path: path)
          return schema_errors unless schema_errors.valid?

          return unless instance.is_a?(Numeric)
          return if handled_by_min_max?(schema)

          errors = MIN_KEYWORDS.each_with_object([]) do |(keyword, operator, text), memo|
            next unless schema.key?(keyword)

            valid = schema[keyword].public_send(operator, instance)
            next if valid

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
          MIN_KEYWORDS.each_with_object(JSONSchema.empty_result) do |(keyword, _, _), memo|
            next unless schema.key?(keyword)
            next if schema[keyword].is_a?(Numeric)

            result = JSONSchema.schema_error(path, keyword, "must be a number")
            memo.merge!(result)
          end
        end

        def handled_by_min_max?(schema)
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
