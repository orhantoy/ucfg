# frozen_string_literal: true

require "ucfg/validation_error"

module Ucfg
  class ValidationResult
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
