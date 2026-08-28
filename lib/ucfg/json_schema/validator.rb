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

        def validate(_instance, _schema, path:, context:)
          raise NotImplementedError, "#{name} must implement .validate"
        end

        def subject(path)
          path.empty? ? "Root value" : "Property `#{path.join('.')}`"
        end
      end
    end
  end
end
