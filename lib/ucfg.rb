# frozen_string_literal: true

require "ucfg/version"
require "ucfg/json_schema"
require "ucfg/validation_result"

module Ucfg
  class Error < StandardError; end

  def self.validate(config, schema)
    result = JSONSchema.validate_recursively(config, schema, path: [])
    ValidationResult.from_json_schema_validation(result)
  end
end
