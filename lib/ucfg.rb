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
    if schema.key?("additionalProperties") && schema["additionalProperties"] == false
      schema_properties_keys = schema["properties"].keys
      config_keys = config.keys
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
        if schema["properties"][key]["type"].is_a?(String) && schema["properties"][key]["type"] == value_type(value)
          next
        elsif schema["properties"][key]["type"].is_a?(Array) && schema["properties"][key]["type"].include?(value_type(value))
          next
        else
          valid = false
          errors << "Property `#{(config_path + [key]).join('.')}` must be of type #{type_to_sentence(schema['properties'][key]['type'])} (#{value_type_error(value)})"
        end
      end

      if schema["properties"].key?(key) && schema["properties"][key].key?("enum") && schema["properties"][key]["enum"].is_a?(Array)
        unless schema["properties"][key]["enum"].include?(value)
          valid = false
          errors << "Property `#{(config_path + [key]).join('.')}` contains an unsupported value (provided `#{value}`)"
        end
      end

      if schema["properties"].key?(key) && schema["properties"][key].key?("const")
        unless schema["properties"][key]["const"] == value
          valid = false
          errors << "Property `#{(config_path + [key]).join('.')}` must have value `#{schema['properties'][key]['const']}` (provided `#{value}`)"
        end
      end
    end

    schema["properties"]&.each do |key, value|
      next unless config[key].is_a?(Hash)

      new_config = config[key]
      new_schema = value
      recursion_result = validate_recursively(new_config, new_schema, config_path + [key])
      errors.concat(recursion_result.errors)
      valid = false unless recursion_result.valid?
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
    return "null" if value.nil?
    return "number" if value.is_a?(Numeric)
    return "array" if value.is_a?(Array)
    return "object" if value.is_a?(Object)
  end

  def self.type_to_sentence(type)
    if type.is_a?(String)
      "`#{type}`"
    elsif type.is_a?(Array)
      type.map { |t| "`#{t}`" }.join(" or ")
    end
  end

  def self.value_type_error(value)
    if value.nil?
      "provided `null`"
    else
      "provided value `#{value}` of type `#{value_type(value)}`"
    end
  end
end
