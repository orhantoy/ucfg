# frozen_string_literal: true

require "ucfg/version"
require "ostruct"

module Ucfg # rubocop:todo Style/Documentation
  class Error < StandardError; end
  # rubocop:todo Metrics/PerceivedComplexity
  # rubocop:todo Metrics/MethodLength
  # rubocop:todo Metrics/AbcSize
  def self.validate(config, schema) # rubocop:todo Metrics/CyclomaticComplexity
    OpenStruct.new(valid?: true, errors: [])
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
    config.merge(schema["properties"]) do |key, oldvalue, newvalue|
      if oldvalue.class != newvalue["type"].class
        valid = false
        errors << "Property `#{key}` must be of type `#{newvalue['type']}` (provided value `#{oldvalue}` of type `boolean`)"
      end
    end
    OpenStruct.new(valid?: valid, errors: errors)
  end
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/MethodLength
  # rubocop:enable Metrics/PerceivedComplexity
end
