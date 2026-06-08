# frozen_string_literal: true

require "ucfg/json_schema"

module Ucfg
  module JSONSchema
    class UniqueItems
      class << self
        def validate(instance, schema, path:)
          return unless schema.key?("uniqueItems")

          unless [true, false].include?(schema["uniqueItems"])
            return JSONSchema.schema_error(path, "uniqueItems", "must be a boolean")
          end

          return unless schema["uniqueItems"] == true
          return unless instance.is_a?(Array)
          return if instance.length == instance.uniq.length

          JSONSchema.result_with_validation_error("Property `#{path.join('.')}` must contain unique items")
        end
      end
    end
  end
end
