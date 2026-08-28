# frozen_string_literal: true

require "ucfg/json_schema/validation_context"

module Ucfg
  module JSONSchema
    class << self
      def validate_recursively(instance, schema, path:, context: ValidationContext.new)
        unless schema.is_a?(Hash)
          return context.add_schema_error(path, "schema", "must be an object")
        end

        validator_registry.validators_for(schema).each do |validator|
          validator.validate(instance, schema, path: path, context: context)
        end
        context
      end

      def compile_pattern_properties(pattern_properties, path:, context:)
        pattern_properties.each_with_object([]) do |(pattern, sub_schema), compiled_patterns|
          unless sub_schema.is_a?(Hash)
            context.add_error(
              "Schema keyword `#{(path + [pattern.to_s]).join('.')}` must be an object",
              path: path,
              keyword: pattern.to_s,
              type: :schema,
            )
            next
          end

          begin
            compiled_patterns << [Regexp.new(pattern), sub_schema]
          rescue RegexpError, TypeError
            context.add_error(
              "Pattern `#{(path + [pattern.to_s]).join('.')}` is not a valid regular expression",
              path: path,
              keyword: pattern.to_s,
              type: :schema,
            )
          end
        end
      end

      private

      def validator_registry
        require "ucfg/json_schema" unless const_defined?(:VALIDATOR_REGISTRY, false)
        VALIDATOR_REGISTRY
      end
    end
  end
end
