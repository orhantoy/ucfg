# frozen_string_literal: true

require "ucfg/json_schema/validation_context"

module Ucfg
  module JSONSchema
    class << self
      def validate_recursively(instance, schema, path:, context: ValidationContext.new)
        return context.add_schema_error(path, "schema", "must be an object") unless schema.is_a?(Hash)

        validator_registry.validators_for(schema).each do |validator|
          validator.validate(instance, schema, path: path, context: context)
        end
        context
      end

      def compile_pattern_properties(pattern_properties, path:, context:)
        pattern_properties.each_with_object([]) do |(pattern, sub_schema), compiled_patterns|
          unless sub_schema.is_a?(Hash)
            add_pattern_schema_error(pattern, path: path, context: context)
            next
          end

          regexp = compile_pattern(pattern, path: path, context: context)
          compiled_patterns << [regexp, sub_schema] if regexp
        end
      end

      private

      def add_pattern_schema_error(pattern, path:, context:)
        context.add_error(
          "Schema keyword `#{(path + [pattern.to_s]).join('.')}` must be an object",
          path: path,
          keyword: pattern.to_s,
          type: :schema,
        )
      end

      def compile_pattern(pattern, path:, context:)
        Regexp.new(pattern)
      rescue RegexpError, TypeError
        context.add_error(
          "Pattern `#{(path + [pattern.to_s]).join('.')}` is not a valid regular expression",
          path: path,
          keyword: pattern.to_s,
          type: :schema,
        )
        nil
      end

      def validator_registry
        require "ucfg/json_schema" unless const_defined?(:VALIDATOR_REGISTRY, false)
        VALIDATOR_REGISTRY
      end
    end
  end
end
