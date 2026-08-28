# frozen_string_literal: true

require "ucfg/json_schema/size_constraint"

module Ucfg
  module JSONSchema
    class MinLength < SizeConstraint
      configure(
        keyword: "minLength",
        type: String,
        operator: :>=,
        requirement: "have at least",
        unit: "characters",
        provided_label: "length ",
      )
    end
  end
end
