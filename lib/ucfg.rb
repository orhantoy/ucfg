# frozen_string_literal: true

require "ucfg/version"
require "ostruct"

module Ucfg # rubocop:todo Style/Documentation
  class Error < StandardError; end
  # rubocop:todo Metrics/PerceivedComplexity
  # rubocop:todo Metrics/MethodLength
  # rubocop:todo Metrics/AbcSize
  def self.validate(config, schema)
    # rubocop:todo Metrics/CyclomaticComplexity
    valid = true
    errors = []

    # fails if required property is missing
    if schema.key?("required")
      schema["required"].each do |required_key|
        unless config.key?(required_key)
          valid = false
          errors << "Required property `#{required_key}` is missing"
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
          errors << "Property `#{key}` is not supported"
        end
      end
    end
    # fails if string property is provided as other type
    config.each do |key, value|
      if schema["properties"].key?(key) && schema["properties"][key].key?("type")
        if schema["properties"][key]["type"] != value_type(value)
          valid = false
          errors << "Property `#{key}` must be of type `#{schema['properties'][key]['type']}` (provided value `#{value}` of type `#{value_type(value)}`)"
        end
      end
    end

    config.each do |key0, value0| #Key0: devotus, value0:{"version": "7.9"}
      if value0.is_a?(Hash) #true
        value0.each do |key1, value1| #key1: version, value1: 7.9
          schema.each do |key2, value2| #key2: properties, value2: "devotus": {....
            if schema.key?("properties") && value2.is_a?(Object) #true
              value2.each do |key3, value3| #key3: devotus, value3: {"required": ["name"],...
                if key3 == key0 && value3.is_a?(Object)
                  value3.each do |key4, value4| #key4: required, value4: name
                    if schema[key2][key3].key?("required") && config[key0].values.include?(value4)
                      valid = false
                      errors << "Required property `#{key3.value4}` is missing"
                    end
                  end
                end
              end
            end
          end
        end
      end
    end

    OpenStruct.new(valid?: valid, errors: errors)
  end
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/MethodLength
  # rubocop:enable Metrics/PerceivedComplexity

  def self.value_type(value)
    return "string" if value.is_a?(String)
    return "boolean" if value.is_a?(TrueClass) || value.is_a?(FalseClass)
  end
end
