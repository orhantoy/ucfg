# frozen_string_literal: true

require "ucfg/error_normalizer"

module Ucfg
  class LoadResult
    attr_reader :config, :error_details, :errors

    def initialize(config: nil, errors: [], error_details: nil)
      @config = config
      @error_details = ErrorNormalizer.normalize(error_details || errors, default_type: :load)
      @errors = @error_details.map(&:message).freeze
      freeze
    end

    def valid?
      error_details.empty?
    end
  end
end
