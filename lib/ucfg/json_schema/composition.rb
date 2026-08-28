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

        def validate(instance, schema, path:)
          return unless schema.key?(@keyword)

          subschemas = schema[@keyword]
          unless subschemas.is_a?(Array)
            return JSONSchema.schema_error(path, @keyword, "must be an array of schemas")
          end

          return validate_all(instance, subschemas, path: path) if @mode == :all

          schema_errors = invalid_subschema_errors(subschemas, path: path)
          return schema_errors unless schema_errors.valid?

          matches = matching_subschema_count(instance, subschemas, path: path)
          return if valid_match_count?(matches)

          JSONSchema.result_with_validation_error(
            failure_message(path, matches),
            path: path,
            keyword: @keyword,
          )
        end

        private

        def validate_all(instance, subschemas, path:)
          subschemas.each_with_index.reduce(JSONSchema.empty_result) do |memo, (subschema, index)|
            result =
              if subschema.is_a?(Hash)
                JSONSchema.validate_recursively(instance, subschema, path: path)
              else
                JSONSchema.schema_error(path + [@keyword], index, "must be an object")
              end
            JSONSchema.combine_results(memo, result)
          end
        end

        def invalid_subschema_errors(subschemas, path:)
          subschemas.each_with_index.reduce(JSONSchema.empty_result) do |memo, (subschema, index)|
            result = JSONSchema.schema_error(path + [@keyword], index, "must be an object") unless subschema.is_a?(Hash)
            JSONSchema.combine_results(memo, result)
          end
        end

        def matching_subschema_count(instance, subschemas, path:)
          subschemas.count do |subschema|
            JSONSchema.validate_recursively(instance, subschema, path: path).valid?
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
