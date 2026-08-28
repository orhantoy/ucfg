# frozen_string_literal: true

require "ucfg/json_schema/numeric_bound"

module Ucfg
  module JSONSchema
    class Min < NumericBound
      configure [
        ["min", :<=, "greater than or equal to"],
        ["minimum", :<=, "greater than or equal to"],
        ["exclusiveMinimum", :<, "greater than"],
      ]
    end
  end
end
