# frozen_string_literal: true

require "ucfg/json_schema/composition"

module Ucfg
  module JSONSchema
    class AnyOf < Composition
      configure keyword: "anyOf", mode: :any
    end
  end
end
