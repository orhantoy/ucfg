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
          return unless instance.is_a?(Numeric)
          return if handled_by_min_max?(schema)

          errors = MIN_KEYWORDS.each_with_object([]) do |(keyword, operator, text), memo|
            next unless schema.key?(keyword)
            next unless schema[keyword].is_a?(Numeric)

            valid = schema[keyword].public_send(operator, instance)
            next if valid

            memo << "Property `#{path.join('.')}` must be #{text} #{schema[keyword]} (provided #{instance})"
          end

          return if errors.empty?

          { validation_errors: errors }
        end

        private

        def handled_by_min_max?(schema)
          schema.key?("min") &&
            schema.key?("max") &&
            !schema.key?("minimum") &&
            !schema.key?("maximum") &&
            !schema.key?("exclusiveMinimum") &&
            !schema.key?("exclusiveMaximum")
        end
      end
    end
  end
end
