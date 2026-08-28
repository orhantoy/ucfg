# frozen_string_literal: true

require "ucfg/json_schema/size_constraint"

module Ucfg
  module JSONSchema
    class MaxLength < SizeConstraint
      configure(
        keyword: "maxLength",
        type: String,
        operator: :<=,
        requirement: "have at most",
        unit: "characters",
        provided_label: "length ",
      )
    end
  end
end
