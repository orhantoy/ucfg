# frozen_string_literal: true

require "yaml"

module Ucfg
  class VariableSubstitution
    PREFIX = "${"
    SUFFIX = "}"

    def initialize(full_config, options = {})
      @full_config = full_config
      @options = options
    end

    def substitute
      substitute_variables(full_config)
    end

    private

    attr_reader :full_config, :options

    def substitute_variables(config)
      case config
      when Hash
        config.transform_values { |val| substitute_variables(val) }
      when Array
        config.map { |val| substitute_variables(val) }
      when String
        final_value = variable_substitutions(config)
        Psych::ScalarScanner.new(Psych::ClassLoader.new).tokenize(final_value)
      else
        config
      end
    end

    def variable_substitutions(string, visited_placeholders = Set.new)
      while (start_index = string.index(PREFIX))
        break unless (end_index = find_placeholder_end_index(string, start_index))

        placeholder = string[(start_index + PREFIX.length)..(end_index - SUFFIX.length)]
        if visited_placeholders.include?(placeholder)
          raise InvalidSubstitution, "Circular placeholder reference '#{placeholder}' in property definitions"
        end

        visited_placeholders.add(placeholder)

        placeholder = variable_substitutions(placeholder, visited_placeholders)
        placeholder, _, default_value = placeholder.partition(":")
        if !options.key?(placeholder) && default_value.to_s.empty?
          raise InvalidSubstitution, "Could not resolve placeholder '#{placeholder}'"
        end

        unquoted_default_value =
          if default_value.start_with?('"') && default_value.end_with?('"')
            default_value[1..-2]
          elsif default_value.start_with?("'") && default_value.end_with?("'")
            default_value[1..-2]
          else
            default_value
          end
        property_value = options.key?(placeholder) ? options.fetch(placeholder) : unquoted_default_value
        final_value = variable_substitutions(property_value, visited_placeholders)
        string = string[0...start_index] + final_value + string[(end_index + 1)..-1]

        visited_placeholders.delete(placeholder)
      end

      string
    end

    def find_placeholder_end_index(config, start_index)
      index = start_index + PREFIX.length
      within_nested_placedholder = 0
      while index < config.length
        if config[index...(index + SUFFIX.length)] == SUFFIX
          return index unless within_nested_placedholder > 0

          within_nested_placedholder -= 1
          index += SUFFIX.length
        elsif config[index...(index + PREFIX.length)] == PREFIX
          within_nested_placedholder += 1
          index += PREFIX.length
        else
          index += 1
        end
      end
    end
  end
end
