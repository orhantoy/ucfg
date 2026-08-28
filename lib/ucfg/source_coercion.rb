# frozen_string_literal: true

require "ucfg/error"

module Ucfg
  module SourceCoercion
    module_function

    def to_string(source, label:)
      return source.to_str if source.respond_to?(:to_str)

      raise Error, "#{label} source must be a string"
    end
  end
end
