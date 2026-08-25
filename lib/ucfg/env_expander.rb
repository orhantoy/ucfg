# frozen_string_literal: true

module Ucfg
  module EnvExpander
    class << self
      def expand(value, env: ENV, parsers: {})
        case value
        when Hash
          value.transform_values { |child| expand(child, env: env, parsers: parsers) }
        when Array
          value.map { |child| expand(child, env: env, parsers: parsers) }
        when String
          expand_string(value, env: env, parsers: parsers)
        else
          value
        end
      end

      def expand_source(source, env: ENV)
        expand_string(normalize_source(source), env: env, parsers: {}).to_s
      end

      private

      def normalize_source(source)
        return source.to_str if source.respond_to?(:to_str)

        raise Error, "Template source must be a string"
      end

      def expand_string(value, env:, parsers:, parse_whole: true)
        pieces = parse_pieces(value, env: env, parsers: parsers)
        return value if pieces.nil?

        if parse_whole && pieces.length == 1 && pieces.first[:type] == :expansion
          return parse_env_value(pieces.first[:value], parser: parser_for(pieces.first[:name], parsers))
        end

        pieces.map { |piece| piece[:value] }.join
      end

      def parse_pieces(value, env:, parsers:)
        pieces = []
        index = 0
        saw_expansion = false

        while index < value.length
          dollar_index = value.index("$", index)
          unless dollar_index
            append_literal(pieces, value[index..]) if index < value.length
            break
          end

          append_literal(pieces, value[index...dollar_index]) if dollar_index > index

          next_char = value[dollar_index + 1]
          case next_char
          when "$"
            append_literal(pieces, "$")
            index = dollar_index + 2
          when "}"
            append_literal(pieces, "$}")
            index = dollar_index + 2
          when "{"
            close_index = find_expansion_close(value, dollar_index + 2)
            raise Error, "Missing `}` in environment expansion" unless close_index

            expression = value[(dollar_index + 2)...close_index]
            resolved = resolve_expression(expression, env: env, parsers: parsers)
            pieces << { :type => :expansion, :name => resolved[:name], :value => resolved[:value] }
            saw_expansion = true
            index = close_index + 1
          else
            append_literal(pieces, "$")
            index = dollar_index + 1
          end
        end

        return nil unless saw_expansion

        pieces
      end

      def append_literal(pieces, value)
        return if value.nil? || value.empty?

        if pieces.last&.fetch(:type) == :literal
          pieces.last[:value] += value
        else
          pieces << { :type => :literal, :value => value }
        end
      end

      def resolve_expression(expression, env:, parsers:)
        name, default = expression.split(":", 2)
        raise Error, "Empty environment expansion" if name.nil? || name.empty?

        value = env[name]
        return { :name => name, :value => value } if value && !value.empty?
        return { :name => name, :value => expand_string(default, env: env, parsers: parsers, parse_whole: false) } unless default.nil?

        raise Error, "Environment variable `#{name}` is not set"
      end

      def find_expansion_close(value, index)
        depth = 1

        while index < value.length
          if value[index] == "$" && value[index + 1] == "{"
            depth += 1
            index += 2
            next
          end

          if value[index] == "}"
            depth -= 1
            return index if depth.zero?
          end

          index += 1
        end

        nil
      end

      def parse_env_value(value, parser:)
        return value unless value.is_a?(String)
        return apply_parser(value, parser) if parser

        parse_env_scalar(value)
      end

      def apply_parser(value, parser)
        return value.split(",", -1).map { |item| parse_env_scalar(item.strip) } if [:csv, "csv"].include?(parser)
        return parser.call(value) if parser.respond_to?(:call)

        raise Error, "Unsupported environment parser `#{parser}`"
      end

      def parse_env_scalar(value)
        case value
        when "true"
          true
        when "false"
          false
        when "null"
          nil
        else
          parse_number(value) || value
        end
      end

      def parser_for(name, parsers)
        parsers[name] || parsers[name.to_sym]
      end

      def parse_number(value)
        return Integer(value, 10) if value.match?(/\A-?(?:0|[1-9][0-9]*)\z/)
        return Float(value) if value.match?(/\A-?(?:0|[1-9][0-9]*)(?:\.[0-9]+)?(?:[eE][+-]?[0-9]+)\z/)
        return Float(value) if value.match?(/\A-?(?:0|[1-9][0-9]*)\.[0-9]+\z/)

        nil
      end
    end
  end
end
