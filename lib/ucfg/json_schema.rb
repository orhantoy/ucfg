# frozen_string_literal: true

require "ucfg/json_schema/additional_properties"
require "ucfg/json_schema/all_of"
require "ucfg/json_schema/any_of"
require "ucfg/json_schema/const"
require "ucfg/json_schema/enum"
require "ucfg/json_schema/items"
require "ucfg/json_schema/max_items"
require "ucfg/json_schema/max_length"
require "ucfg/json_schema/min_max"
require "ucfg/json_schema/min_items"
require "ucfg/json_schema/min_length"
require "ucfg/json_schema/max"
require "ucfg/json_schema/min"
require "ucfg/json_schema/pattern"
require "ucfg/json_schema/one_of"
require "ucfg/json_schema/properties"
require "ucfg/json_schema/required"
require "ucfg/json_schema/type"
require "ucfg/json_schema/unique_items"
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
          JSONSchema::MaxItems,
          JSONSchema::MaxLength,
          JSONSchema::Min,
          JSONSchema::MinMax,
          JSONSchema::MinItems,
          JSONSchema::MinLength,
          JSONSchema::Pattern,
          JSONSchema::OneOf,
          JSONSchema::Required,
          JSONSchema::Type,
          JSONSchema::UniqueItems,
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
    end
  end
end
