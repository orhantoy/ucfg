# frozen_string_literal: true

require "ucfg/validation_result"

module Ucfg
  module JSONSchema
    class << self
      def validate_recursively(instance, schema, path:)
        unless schema.is_a?(Hash)
          return schema_error(path, "schema", "must be an object")
        end

        validator_registry.validators_for(schema).reduce(empty_result) do |memo, validator|
          result = validator.validate(instance, schema, path: path)
          combine_results(memo, result)
        end
      end

      def combine_results(a, b)
        return a if b.nil?
        return b if a.nil?

        ValidationResult.new(error_details: a.error_details + b.error_details)
      end

      def empty_result
        ValidationResult.new
      end

      def result_with_validation_error(message, path: nil, keyword: nil, type: :validation)
        ValidationResult.new(
          error_details: [
            ValidationError.new(message: message, path: path, keyword: keyword, type: type),
          ],
        )
      end

      def schema_error(path, keyword, expectation)
        result_with_validation_error(
          "Schema keyword `#{schema_path(path, keyword)}` #{expectation}",
          path: path,
          keyword: keyword,
          type: :schema,
        )
      end

      def compile_pattern_properties(pattern_properties, path:)
        pattern_properties.reduce([[], empty_result]) do |(compiled_patterns, errors), (pattern, sub_schema)|
          unless sub_schema.is_a?(Hash)
            result = result_with_validation_error(
              "Schema keyword `#{(path + [pattern.to_s]).join('.')}` must be an object",
              path: path,
              keyword: pattern.to_s,
              type: :schema,
            )
            errors = combine_results(errors, result)
            next [compiled_patterns, errors]
          end

          begin
            compiled_patterns << [Regexp.new(pattern), sub_schema]
          rescue RegexpError, TypeError
            result = result_with_validation_error(
              "Pattern `#{(path + [pattern.to_s]).join('.')}` is not a valid regular expression",
              path: path,
              keyword: pattern.to_s,
              type: :schema,
            )
            errors = combine_results(errors, result)
          end

          [compiled_patterns, errors]
        end
      end

      def schema_path(path, keyword)
        (path + [keyword]).join(".")
      end

      private

      def validator_registry
        require "ucfg/json_schema" unless const_defined?(:VALIDATOR_REGISTRY, false)
        VALIDATOR_REGISTRY
      end
    end
  end
end
