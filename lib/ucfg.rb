# frozen_string_literal: true

require "ucfg/version"
require "ucfg/variable_substitution"
require "yaml"

module Ucfg
  class Error < StandardError; end
  class InvalidYAMLSyntax < Error; end
  class InvalidSubstitution < Error; end

  # This is a modified version of Hash#deep_merge! from ActiveSupport: https://github.com/rails/rails/blob/b9ca94caea2ca6a6cc09abaffaad67b447134079/activesupport/lib/active_support/core_ext/hash/deep_merge.rb
  module DeepMergeableHash
    refine Hash do
      def deep_merge!(other_hash, &block)
        merge!(other_hash) do |key, this_val, other_val|
          if this_val.is_a?(Hash) && other_val.is_a?(Hash)
            this_val.dup.deep_merge!(other_val, &block)
          elsif block_given?
            block.call(key, this_val, other_val)
          else
            other_val
          end
        end
      end
    end
  end

  using DeepMergeableHash

  class << self
    def parse(raw, options = ENV)
      value = YAML.safe_load(raw)
      dot_nested_value = dot_to_nested(value)
      VariableSubstitution.new(dot_nested_value, options).substitute
    rescue Psych::SyntaxError
      raise InvalidYAMLSyntax, "Invalid YAML"
    end

    def dot_to_nested(value)
      case value
      when Array
        value.map { |v| dot_to_nested(v) }
      when Hash
        value.each_with_object({}) do |(k, v), out|
          keys_in_path = k.split(".")
          transformed_value = dot_to_nested(v)
          dot_nested_hash = keys_in_path.reverse_each.reduce(transformed_value) { |memo, part| { part => memo } }
          out.deep_merge!(dot_nested_hash)
        end
      else
        value
      end
    end
  end
end
