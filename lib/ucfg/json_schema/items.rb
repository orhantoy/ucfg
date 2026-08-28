# frozen_string_literal: true

require "ucfg/json_schema/validator"

module Ucfg
  module JSONSchema
    class Items < Validator
      handles "items"

      class << self
        def validate(instance, schema, path:, context:)
          return context unless schema.key?("items")

          unless schema["items"].is_a?(Hash)
            return context.add_schema_error(path, "items", "must be an object")
          end

          return context unless instance.is_a?(Array)

          instance.each_with_index do |item, index|
            JSONSchema.validate_recursively(item, schema["items"], path: path + [index], context: context)
          end
          context
        end
      end
    end
  end
end
