# frozen_string_literal: true

require "ucfg/json_schema/size_constraint"

module Ucfg
  module JSONSchema
    class MaxItems < SizeConstraint
      configure keyword: "maxItems", type: Array, operator: :<=, requirement: "contain at most", unit: "items"
    end
  end
end
