# frozen_string_literal: true

require "ucfg/json_schema/validator"

module Ucfg
  module JSONSchema
    class UniqueItems < Validator
      handles "uniqueItems"

      class << self
        def validate(instance, schema, path:, context:)
          return context unless schema.key?("uniqueItems")

          return context.add_schema_error(path, "uniqueItems", "must be a boolean") unless [true, false].include?(schema["uniqueItems"])

          return context unless schema["uniqueItems"] == true
          return context unless instance.is_a?(Array)
          return context if instance.length == instance.uniq.length

          context.add_error(
            "#{subject(path)} must contain unique items",
            path: path,
            keyword: "uniqueItems",
          )
        end
      end
    end
  end
end
