# frozen_string_literal: true

require "ucfg/error"

module Ucfg
  module ConfigMerger
    class << self
      def merge(base, override)
        merge_hashes(normalize_input(base, "base"), normalize_input(override, "override"))
      end

      private

      def normalize_input(value, label)
        return {} if value.nil?
        return value if value.is_a?(Hash)

        raise Error, "#{label.capitalize} config must be a Hash or nil"
      end

      def merge_hashes(base, override)
        merged = deep_clone(base)

        override.each do |key, override_value|
          base_value = merged[key]

          merged[key] =
            if base_value.is_a?(Hash) && override_value.is_a?(Hash)
              merge_hashes(base_value, override_value)
            else
              deep_clone(override_value)
            end
        end

        merged
      end

      def deep_clone(value)
        case value
        when Hash
          value.each_with_object({}) { |(key, nested), copy| copy[key] = deep_clone(nested) }
        when Array
          value.map { |item| deep_clone(item) }
        when String
          value.dup
        else
          value
        end
      end
    end
  end
end
