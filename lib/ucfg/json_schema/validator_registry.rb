# frozen_string_literal: true

require "ucfg/json_schema/validator"

module Ucfg
  module JSONSchema
    class ValidatorRegistry
      attr_reader :validators

      def initialize(validators)
        @validators = validators.map { |validator| validate_strategy(validator) }.freeze
      end

      def validators_for(schema)
        validators.select do |validator|
          validator.handles.any? { |keyword| schema.key?(keyword) }
        end
      end

      private

      def validate_strategy(validator)
        valid_strategy =
          validator.respond_to?(:validate) &&
          validator.respond_to?(:handles) &&
          !validator.handles.empty? &&
          validator.method(:validate).owner != Validator.singleton_class

        unless valid_strategy
          raise ArgumentError, "validators must define .validate and handle at least one keyword"
        end

        validator
      end
    end
  end
end
