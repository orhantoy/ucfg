# frozen_string_literal: true

require "ucfg/json_schema/validator"

module Ucfg
  module JSONSchema
    class Composition < Validator
      class << self
        def configure(keyword:, mode:)
          handles keyword
          @keyword = keyword
          @mode = mode
        end

        def validate(instance, schema, path:, context:)
          return context unless schema.key?(@keyword)

          subschemas = schema[@keyword]
          unless subschemas.is_a?(Array)
            return context.add_schema_error(path, @keyword, "must be an array of schemas")
          end

          return validate_all(instance, subschemas, path: path, context: context) if @mode == :all

          valid_schemas = validate_subschemas(subschemas, path: path, context: context)
          return context unless valid_schemas

          matches = matching_subschema_count(instance, subschemas, path: path)
          return context if valid_match_count?(matches)

          context.add_error(
            failure_message(path, matches),
            path: path,
            keyword: @keyword,
          )
        end

        private

        def validate_all(instance, subschemas, path:, context:)
          subschemas.each_with_index do |subschema, index|
            if subschema.is_a?(Hash)
              JSONSchema.validate_recursively(instance, subschema, path: path, context: context)
            else
              context.add_schema_error(path + [@keyword], index, "must be an object")
            end
          end
          context
        end

        def validate_subschemas(subschemas, path:, context:)
          valid = true
          subschemas.each_with_index do |subschema, index|
            next if subschema.is_a?(Hash)

            context.add_schema_error(path + [@keyword], index, "must be an object")
            valid = false
          end
          valid
        end

        def matching_subschema_count(instance, subschemas, path:)
          subschemas.count do |subschema|
            JSONSchema.validate_recursively(instance, subschema, path: path, context: ValidationContext.new).valid?
          end
        end

        def valid_match_count?(matches)
          @mode == :any ? matches.positive? : matches == 1
        end

        def failure_message(path, matches)
          if @mode == :any
            "Property `#{path.join('.')}` must match at least one schema in `#{@keyword}`"
          else
            "Property `#{path.join('.')}` must match exactly one schema in `#{@keyword}` (matched #{matches})"
          end
        end
      end
    end
  end
end
