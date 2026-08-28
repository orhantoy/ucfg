# frozen_string_literal: true

require "ucfg/validation_error"
require "ucfg/validation_result"

module Ucfg
  module JSONSchema
    class ValidationContext
      attr_reader :error_details

      def initialize
        @error_details = []
      end

      def add_error(message, path: nil, keyword: nil, type: :validation)
        error_details << ValidationError.new(
          message: message,
          path: path,
          keyword: keyword,
          type: type,
        )
        self
      end

      def add_schema_error(path, keyword, expectation)
        add_error(
          "Schema keyword `#{(path + [keyword]).join('.')}` #{expectation}",
          path: path,
          keyword: keyword,
          type: :schema,
        )
      end

      def valid?
        error_details.empty?
      end

      def error_count
        error_details.length
      end

      def errors
        error_details.map(&:message)
      end

      def to_result
        ValidationResult.new(error_details: error_details)
      end
    end
  end
end
