# frozen_string_literal: true

require "ucfg/json_schema/additional_properties"
require "ucfg/json_schema/all_of"
require "ucfg/json_schema/any_of"
require "ucfg/json_schema/const"
require "ucfg/json_schema/enum"
require "ucfg/json_schema/items"
require "ucfg/json_schema/min_max"
require "ucfg/json_schema/max"
require "ucfg/json_schema/min"
require "ucfg/json_schema/one_of"
require "ucfg/json_schema/pattern_properties"
require "ucfg/json_schema/properties"
require "ucfg/json_schema/required"
require "ucfg/json_schema/type"
require "ucfg/validation_result"

module Ucfg
  module JSONSchema
    class << self
      def validate_recursively(instance, schema, path:)
        [
          JSONSchema::AdditionalProperties,
          JSONSchema::AllOf,
          JSONSchema::AnyOf,
          JSONSchema::Const,
          JSONSchema::Enum,
          JSONSchema::Items,
          JSONSchema::Max,
          JSONSchema::Min,
          JSONSchema::MinMax,
          JSONSchema::OneOf,
          JSONSchema::PatternProperties,
          JSONSchema::Required,
          JSONSchema::Type,
          JSONSchema::Properties,
        ].reduce(empty_result) do |memo, validator|
          result = validator.validate(instance, schema, path: path)
          combine_results(memo, result)
        end
      end

      def combine_results(a, b)
        return a if b.nil?
        return b if a.nil?

        { validation_errors: a.fetch(:validation_errors) + b.fetch(:validation_errors) }
      end

      def empty_result
        { validation_errors: [] }
      end

      def result_with_validation_error(message)
        { validation_errors: [message] }
      end

      def compile_pattern_properties(pattern_properties, path:)
        pattern_properties.reduce([[], empty_result]) do |(compiled_patterns, errors), (pattern, sub_schema)|
          begin
            compiled_patterns << [Regexp.new(pattern), sub_schema]
          rescue RegexpError, TypeError
            result = result_with_validation_error("Pattern `#{(path + [pattern.to_s]).join('.')}` is not a valid regular expression")
            errors = combine_results(errors, result)
          end

          [compiled_patterns, errors]
        end
      end
    end
  end
end
