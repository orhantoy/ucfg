# frozen_string_literal: true

require "ucfg/json_schema/validator"

module Ucfg
  module JSONSchema
    class SizeConstraint < Validator
      class << self
        def configure(keyword:, type:, operator:, requirement:, unit:, provided_label: "")
          handles keyword
          @keyword = keyword
          @type = type
          @operator = operator
          @requirement = requirement
          @unit = unit
          @provided_label = provided_label
        end

        def validate(instance, schema, path:)
          return unless schema.key?(@keyword)

          limit = schema[@keyword]
          unless limit.is_a?(Integer) && limit >= 0
            return JSONSchema.schema_error(path, @keyword, "must be a non-negative integer")
          end

          return unless instance.is_a?(@type)
          return if instance.length.public_send(@operator, limit)

          JSONSchema.result_with_validation_error(
            "Property `#{path.join('.')}` must #{@requirement} #{limit} #{@unit} " \
            "(provided #{@provided_label}#{instance.length})",
            path: path,
            keyword: @keyword,
          )
        end
      end
    end
  end
end
