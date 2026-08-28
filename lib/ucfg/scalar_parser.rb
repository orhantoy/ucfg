# frozen_string_literal: true

module Ucfg
  module ScalarParser
    INTEGER_PATTERN = /\A-?(?:0|[1-9][0-9]*)\z/
    FLOAT_PATTERN = /\A-?(?:0|[1-9][0-9]*)(?:\.[0-9]+(?:[eE][+-]?[0-9]+)?|[eE][+-]?[0-9]+)\z/

    module_function

    def parse(value)
      case value
      when "true"
        true
      when "false"
        false
      when "null"
        nil
      else
        parse_number(value) || value
      end
    end

    def parse_number(value)
      return Integer(value, 10) if value.match?(INTEGER_PATTERN)
      return Float(value) if value.match?(FLOAT_PATTERN)

      nil
    end
  end
end
