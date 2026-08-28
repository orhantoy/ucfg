# frozen_string_literal: true

require "ucfg/json_schema/validation"
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
require "ucfg/json_schema/pattern_properties"
require "ucfg/json_schema/properties"
require "ucfg/json_schema/required"
require "ucfg/json_schema/type"
require "ucfg/json_schema/unique_items"

module Ucfg
  module JSONSchema
    VALIDATORS = [
      JSONSchema::PatternProperties,
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
    ].freeze
  end
end
