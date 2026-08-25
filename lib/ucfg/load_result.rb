# frozen_string_literal: true

require "ucfg/validation_error"

module Ucfg
  class LoadResult
    attr_reader :config, :error_details

    def initialize(config: nil, errors: [], error_details: nil)
      @config = config
      @error_details = normalize_error_details(errors, error_details)
    end

    def errors
      error_details.map(&:message)
    end

    def valid?
      errors.empty?
    end

    private

    def normalize_error_details(errors, error_details)
      Array(error_details || errors).map do |error|
        if error.is_a?(ValidationError)
          error
        elsif error.respond_to?(:to_h)
          hash = error.to_h
          ValidationError.new(
            message: hash.fetch(:message) { hash.fetch("message") },
            path: hash[:path] || hash["path"],
            keyword: hash[:keyword] || hash["keyword"],
            type: hash.fetch(:type) { hash.fetch("type", :load) },
          )
        else
          ValidationError.new(message: error.to_s, type: :load)
        end
      end
    end
  end
end
