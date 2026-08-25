# frozen_string_literal: true

require "ucfg/validation_error"

module Ucfg
  class ValidationResult
    class << self
      def from_json_schema_validation(result)
        return new if result.nil?
        return result if result.is_a?(self)

        new(validation_errors: result.fetch(:validation_errors), error_details: result[:error_details])
      end
    end

    attr_reader :error_details

    def initialize(validation_errors: [], error_details: nil)
      @error_details = normalize_error_details(validation_errors, error_details)
    end

    def validation_errors
      error_details.map(&:message)
    end

    alias errors validation_errors

    def valid?
      error_details.empty?
    end

    def merge!(other)
      @error_details.concat(other.error_details)
      self
    end

    private

    def normalize_error_details(validation_errors, error_details)
      Array(error_details || validation_errors).map do |error|
        if error.is_a?(ValidationError)
          error
        elsif error.respond_to?(:to_h)
          hash = error.to_h
          ValidationError.new(
            message: hash.fetch(:message) { hash.fetch("message") },
            path: hash[:path] || hash["path"],
            keyword: hash[:keyword] || hash["keyword"],
            type: hash.fetch(:type) { hash.fetch("type", :validation) },
          )
        else
          ValidationError.new(message: error.to_s)
        end
      end
    end
  end
end
