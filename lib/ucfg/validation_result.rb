# frozen_string_literal: true

require "ucfg/error_normalizer"

module Ucfg
  class ValidationResult
    attr_reader :error_details

    def initialize(validation_errors: [], error_details: nil)
      @error_details = ErrorNormalizer.normalize(error_details || validation_errors, default_type: :validation)
      @errors = @error_details.map(&:message).freeze
      freeze
    end

    def validation_errors
      @errors
    end

    alias errors validation_errors

    def valid?
      error_details.empty?
    end
  end
end
