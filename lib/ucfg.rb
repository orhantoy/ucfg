require "ucfg/version"
require "ostruct"

module Ucfg
  class Error < StandardError; end
  # Your code goes here...

  def self.validate(config, schema)
    valid = true
    errors = []

    if schema.key?('required')
      schema['required'].each do |required_key|
        unless config.key?(required_key)
          valid = false
          errors << "Required property `#{required_key}` is missing"
        end
      end
    end

    OpenStruct.new(:valid? => valid, :errors => errors)
  end
end
