# frozen_string_literal: true

require "ucfg/json_schema"

module Ucfg
  module JSONSchema
    class Items
      class << self
        def validate(instance, schema, path:)
          return unless schema.key?("items")

          unless schema["items"].is_a?(Hash)
            return JSONSchema.schema_error(path, "items", "must be an object")
          end

          return unless instance.is_a?(Array)

          instance.each_with_index.reduce(JSONSchema.empty_result) do |memo, (item, index)|
            result = JSONSchema.validate_recursively(item, schema["items"], path: path + [index])
            JSONSchema.combine_results(memo, result)
          end
        end
      end
    end
  end
end
