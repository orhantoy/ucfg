# frozen_string_literal: true

module Ucfg
  class ValidationError
    attr_reader :message, :path, :keyword, :type

    def initialize(message:, path: nil, keyword: nil, type: :validation)
      @message = message
      @path = path&.dup&.freeze
      @keyword = keyword
      @type = type
    end

    def to_h
      {
        :message => message,
        :path => path,
        :keyword => keyword,
        :type => type,
      }
    end

    def to_s
      message
    end

    def ==(other)
      if other.is_a?(String)
        message == other
      elsif other.is_a?(self.class)
        to_h == other.to_h
      else
        super
      end
    end
  end
end
