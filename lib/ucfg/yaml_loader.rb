# frozen_string_literal: true

require "psych"
require "ucfg/env_expander"

module Ucfg
  module YAMLLoader
    class << self
      def load(source, env: false, env_parsers: {})
        yaml = normalize_source(source)

        stream = Psych.parse_stream(yaml)
        raise Error, "YAML document is empty" if stream.children.empty?
        raise Error, "Multi-document YAML is not supported" if stream.children.length > 1

        document = stream.children.first
        raise Error, "YAML document must contain a single root value" unless document&.children&.length == 1

        config = convert_node(document.children.first, path: [])
        env ? EnvExpander.expand(config, parsers: env_parsers) : config
      rescue Psych::SyntaxError => e
        raise Error, "Invalid YAML syntax at line #{e.line}, column #{e.column}: #{e.problem}"
      end

      private

      def normalize_source(source)
        return source.to_str if source.respond_to?(:to_str)

        raise Error, "YAML source must be a string"
      end

      def convert_node(node, path:)
        reject_anchor!(node)
        reject_tag!(node)

        case node
        when Psych::Nodes::Mapping
          convert_mapping(node, path: path)
        when Psych::Nodes::Sequence
          convert_sequence(node, path: path)
        when Psych::Nodes::Scalar
          convert_scalar(node)
        when Psych::Nodes::Alias
          raise_error_at(node, "Aliases and anchors are not supported")
        else
          raise_error_at(node, "Unsupported YAML node #{node.class.name}")
        end
      end

      def convert_mapping(node, path:)
        raise_error_at(node, "Flow style mappings are not supported") if node.style == Psych::Nodes::Mapping::FLOW

        children = node.children
        raise_error_at(node, "Invalid mapping") if children.length.odd?

        children.each_slice(2).each_with_object({}) do |(key_node, value_node), result|
          key = convert_key(key_node)
          insert_mapping_value!(result, key, value_node, path: path)
        end
      end

      def convert_sequence(node, path:)
        raise_error_at(node, "Flow style sequences are not supported") if node.style == Psych::Nodes::Sequence::FLOW

        node.children.each_with_index.map do |child, index|
          convert_node(child, path: path + [index.to_s])
        end
      end

      def convert_key(node)
        unless node.is_a?(Psych::Nodes::Scalar)
          raise_error_at(node, "Only string object keys are supported")
        end

        reject_anchor!(node)
        reject_tag!(node)

        if [Psych::Nodes::Scalar::LITERAL, Psych::Nodes::Scalar::FOLDED].include?(node.style)
          raise_error_at(node, "Block scalars are not supported")
        end

        raise_error_at(node, "Merge keys are not supported") if node.value == "<<"

        node.value
      end

      def convert_scalar(node)
        if [Psych::Nodes::Scalar::LITERAL, Psych::Nodes::Scalar::FOLDED].include?(node.style)
          raise_error_at(node, "Block scalars are not supported")
        end

        return node.value if quoted_scalar?(node)
        return nil if node.value == ""

        case node.value
        when "true"
          true
        when "false"
          false
        when "null"
          nil
        else
          parse_number(node.value) || node.value
        end
      end

      def quoted_scalar?(node)
        [Psych::Nodes::Scalar::SINGLE_QUOTED, Psych::Nodes::Scalar::DOUBLE_QUOTED].include?(node.style)
      end

      def parse_number(value)
        return Integer(value, 10) if value.match?(/\A-?(?:0|[1-9][0-9]*)\z/)
        return Float(value) if value.match?(/\A-?(?:0|[1-9][0-9]*)(?:\.[0-9]+)?(?:[eE][+-]?[0-9]+)\z/)
        return Float(value) if value.match?(/\A-?(?:0|[1-9][0-9]*)\.[0-9]+\z/)

        nil
      end

      def insert_mapping_value!(result, raw_key, value_node, path:)
        segments = raw_key.split(".")
        raise Error, "Invalid dotted key `#{raw_key}`" if segments.any?(&:empty?)

        current = result

        segments[0...-1].each_with_index do |segment, index|
          joined_path = (path + segments[0..index]).join(".")

          if !current.key?(segment)
            current[segment] = {}
          elsif !current[segment].is_a?(Hash)
            raise Error, "Key `#{joined_path}` cannot be both a scalar and an object"
          end

          current = current[segment]
        end

        leaf = segments.last
        full_path = (path + segments).join(".")
        value = convert_node(value_node, path: path + segments)

        if current.key?(leaf)
          existing = current[leaf]

          if existing.is_a?(Hash) != value.is_a?(Hash)
            raise Error, "Key `#{full_path}` cannot be both a scalar and an object"
          end

          if existing.is_a?(Hash)
            merge_mapping_values!(existing, value, path: path + segments)
            return
          end

          raise Error, "Duplicate key `#{full_path}`"
        end

        current[leaf] = value
      end

      def merge_mapping_values!(target, incoming, path:)
        incoming.each do |key, incoming_value|
          full_path = (path + [key]).join(".")

          unless target.key?(key)
            target[key] = incoming_value
            next
          end

          target_value = target[key]

          if target_value.is_a?(Hash) && incoming_value.is_a?(Hash)
            merge_mapping_values!(target_value, incoming_value, path: path + [key])
            next
          end

          if target_value.is_a?(Hash) != incoming_value.is_a?(Hash)
            raise Error, "Key `#{full_path}` cannot be both a scalar and an object"
          end

          raise Error, "Duplicate key `#{full_path}`"
        end
      end

      def reject_anchor!(node)
        return unless node.respond_to?(:anchor) && node.anchor

        raise_error_at(node, "Aliases and anchors are not supported")
      end

      def reject_tag!(node)
        return unless node.respond_to?(:tag) && node.tag

        raise_error_at(node, "Explicit tags are not supported")
      end

      def raise_error_at(node, message)
        line = node.respond_to?(:start_line) ? node.start_line + 1 : nil
        column = node.respond_to?(:start_column) ? node.start_column + 1 : nil

        if line && column
          raise Error, "#{message} at line #{line}, column #{column}"
        end

        raise Error, message
      end
    end
  end
end
