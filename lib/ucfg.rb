# frozen_string_literal: true

require "ucfg/version"
require "ucfg/json_schema"
require "ucfg/validation_result"
require "ucfg/file_loader"
require "ucfg/env_expander"
require "ucfg/template_renderer"
require "ucfg/yaml_loader"

module Ucfg
  class Error < StandardError; end

  def self.validate_yaml(source, schema, erb: false, env: false)
    raise Error, "ERB and environment expansion cannot be enabled together" if erb && env

    rendered_source = TemplateRenderer.render(source, erb: erb)
    config = YAMLLoader.load(rendered_source, env: env)

    validate(config, schema)
  end

  def self.validate(config, schema)
    result = JSONSchema.validate_recursively(config, schema, path: [])
    ValidationResult.from_json_schema_validation(result)
  end
end
