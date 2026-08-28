# frozen_string_literal: true

require "ucfg/json_schema/size_constraint"

module Ucfg
  module JSONSchema
    class MinItems < SizeConstraint
      configure keyword: "minItems", type: Array, operator: :>=, requirement: "contain at least", unit: "items"
    end
  end
end
