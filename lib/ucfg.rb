# frozen_string_literal: true

require "ucfg/version"
require "ostruct"

module Ucfg # rubocop:todo Style/Documentation
  class Error < StandardError; end
  # rubocop:todo Metrics/CyclomaticComplexity
  # rubocop:todo Metrics/PerceivedComplexity
  # rubocop:todo Metrics/MethodLength
  # rubocop:todo Metrics/AbcSize

  def self.validate(config, schema)
    validate_recursively(config, schema, [])
  end

  def self.validate_recursively(config, schema, config_path)
    valid = true
    errors = []

    # fails if required property is missing
    if schema.key?("required")
      schema["required"].each do |required_key|
        unless config.key?(required_key)
          valid = false
          errors << "Required property `#{(config_path + [required_key]).join('.')}` is missing"
        end
      end
    end

    # fails if additional properties are disabled in schema but still provided
    schema_properties_keys = schema["properties"].keys
    config_keys = config.keys
    if schema.key?("additionalProperties") && schema["additionalProperties"] == false
      config_keys.each do |key|
        unless schema_properties_keys.include?(key)
          valid = false
          errors << "Property `#{(config_path + [key]).join('.')}` is not supported"
        end
      end
    end

    # fails if property is provided as other type
    config.each do |key, value|
      if schema["properties"].key?(key) && schema["properties"][key].key?("type")
        if schema["properties"][key]["type"] != value_type(value)
          valid = false
          errors << "Property `#{(config_path + [key]).join('.')}` must be of type `#{schema['properties'][key]['type']}` (provided value `#{value}` of type `#{value_type(value)}`)"
        end
      end
    end

    schema["properties"].each do |key, value|
      if config[key].is_a?(Hash)
        new_config = config[key]
        new_schema = value
        recursion_result = validate_recursively(new_config, new_schema, config_path + [key])
        errors.concat(recursion_result.errors)
        valid = false unless recursion_result.valid?
      end
    end

    OpenStruct.new(valid?: valid, errors: errors)
  end
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/MethodLength
  # rubocop:enable Metrics/PerceivedComplexity
  # rubocop:enable Metrics/CyclomaticComplexity

  def self.value_type(value)
    return "string" if value.is_a?(String)
    return "boolean" if value.is_a?(TrueClass) || value.is_a?(FalseClass)
  end
end
