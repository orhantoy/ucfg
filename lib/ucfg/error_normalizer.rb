# frozen_string_literal: true

require "ucfg/validation_error"

module Ucfg
  module ErrorNormalizer
    module_function

    def normalize(errors, default_type:)
      Array(errors).map { |error| normalize_error(error, default_type: default_type) }.freeze
    end

    def normalize_error(error, default_type:)
      return error if error.is_a?(ValidationError)
      return ValidationError.new(message: error.to_s, type: default_type) unless error.respond_to?(:to_h)

      hash = error.to_h
      ValidationError.new(
        message: hash.fetch(:message) { hash.fetch("message") },
        path: hash[:path] || hash["path"],
        keyword: hash[:keyword] || hash["keyword"],
        type: hash.fetch(:type) { hash.fetch("type", default_type) },
      )
    end
    private_class_method :normalize_error
  end
end
