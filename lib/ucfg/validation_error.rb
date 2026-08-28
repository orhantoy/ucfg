# frozen_string_literal: true

module Ucfg
  class ValidationError
    attr_reader :message, :path, :keyword, :type

    def initialize(message:, path: nil, keyword: nil, type: :validation)
      @message = immutable_string(message)
      @path = path&.map { |segment| immutable_string(segment) }&.freeze
      @keyword = immutable_string(keyword)
      @type = immutable_string(type)
      freeze
    end

    def to_h
      {
        message: message,
        path: path,
        keyword: keyword,
        type: type,
      }
    end

    def to_s
      message
    end

    def ==(other)
      other.instance_of?(self.class) && to_h == other.to_h
    end
    alias eql? ==

    def hash
      [self.class, message, path, keyword, type].hash
    end

    private

    def immutable_string(value)
      value.is_a?(String) ? value.dup.freeze : value
    end
  end
end
