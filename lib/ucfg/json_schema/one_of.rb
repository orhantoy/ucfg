# frozen_string_literal: true

require "ucfg/json_schema/composition"

module Ucfg
  module JSONSchema
    class OneOf < Composition
      configure keyword: "oneOf", mode: :one
    end
  end
end
