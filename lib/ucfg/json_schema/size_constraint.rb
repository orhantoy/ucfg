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

        def validate(instance, schema, path:, context:)
          return context unless schema.key?(@keyword)

          limit = schema[@keyword]
          return context.add_schema_error(path, @keyword, "must be a non-negative integer") unless limit.is_a?(Integer) && limit >= 0

          return context unless instance.is_a?(@type)
          return context if instance.length.public_send(@operator, limit)

          context.add_error(
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
