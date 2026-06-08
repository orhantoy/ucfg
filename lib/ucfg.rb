# frozen_string_literal: true

require "ucfg/version"
require "ucfg/json_schema"
require "ucfg/validation_result"
require "ucfg/file_loader"
require "ucfg/template_renderer"
require "ucfg/yaml_loader"

module Ucfg
  class Error < StandardError; end

  def self.load_yaml(source, erb: false)
    rendered = TemplateRenderer.render(source, erb: erb)
    YAMLLoader.load(rendered)
  end

  def self.load_file(path, erb: false)
    source = FileLoader.read(path)
    load_yaml(source, erb: erb)
  end

  def self.validate_file(path, schema, erb: false)
    config = load_file(path, erb: erb)
    validate(config, schema)
  end

  def self.validate_yaml(source, schema)
    validate(load_yaml(source), schema)
  end

  def self.validate(config, schema)
    result = JSONSchema.validate_recursively(config, schema, path: [])
    ValidationResult.from_json_schema_validation(result)
  end
end
