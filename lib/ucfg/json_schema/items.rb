# frozen_string_literal: true

require "ucfg/json_schema"

module Ucfg
  module JSONSchema
    class Items
      class << self
        def validate(instance, schema, path:)
          return unless schema.key?("items")
          return unless instance.is_a?(Array)

          if schema["items"].is_a?(Hash)
            instance.each_with_index.reduce(JSONSchema.empty_result) do |memo, (item, index)|
              result = JSONSchema.validate_recursively(item, schema["items"], path: path + [index])
              JSONSchema.combine_results(memo, result)
            end
          end
        end
      end
    end
  end
end
