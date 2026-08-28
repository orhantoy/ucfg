# frozen_string_literal: true

require "ucfg/json_schema/numeric_bound"

module Ucfg
  module JSONSchema
    class Max < NumericBound
      configure [
        ["max", :>=, "less than or equal to"],
        ["maximum", :>=, "less than or equal to"],
        ["exclusiveMaximum", :>, "less than"],
      ]
    end
  end
end
