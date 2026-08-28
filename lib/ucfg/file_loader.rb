# frozen_string_literal: true

require "ucfg/error"

module Ucfg
  module FileLoader
    class << self
      def read(path)
        normalized_path = normalize_path(path)
        File.read(normalized_path)
      rescue SystemCallError => e
        raise Error, "Failed to read file `#{normalized_path}`: #{e.message}"
      end

      private

      def normalize_path(path)
        return path.to_path if path.respond_to?(:to_path)
        return path.to_str if path.respond_to?(:to_str)

        raise Error, "File path must be a string or path-like object"
      end
    end
  end
end
