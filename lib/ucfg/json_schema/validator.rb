# frozen_string_literal: true

require "ucfg/json_schema/validation"

module Ucfg
  module JSONSchema
    class Validator
      class << self
        def handles(*keywords)
          @keywords = keywords.map(&:freeze).freeze unless keywords.empty?
          @keywords || []
        end

        def validate(_instance, _schema, path:)
          raise NotImplementedError, "#{name} must implement .validate"
        end
      end
    end
  end
end
