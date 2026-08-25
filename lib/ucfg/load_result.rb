# frozen_string_literal: true

module Ucfg
  class LoadResult
    attr_reader :config, :errors

    def initialize(config: nil, errors: [])
      @config = config
      @errors = errors
    end

    def valid?
      errors.empty?
    end
  end
end
