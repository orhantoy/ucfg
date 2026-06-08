# frozen_string_literal: true

module Ucfg
  class ValidationResult
    class << self
      def from_json_schema_validation(result)
        return new if result.nil?
        return result if result.is_a?(self)

        new(validation_errors: result.fetch(:validation_errors))
      end
    end

    attr_reader :validation_errors

    def initialize(validation_errors: [])
      @validation_errors = validation_errors
    end

    alias errors validation_errors

    def valid?
      validation_errors.empty?
    end

    def merge!(other)
      @validation_errors.concat(other.validation_errors)
      self
    end
  end
end
