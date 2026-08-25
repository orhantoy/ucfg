# frozen_string_literal: true

require "ucfg/version"
require "ucfg/json_schema"
require "ucfg/validation_result"
require "ucfg/load_result"
require "ucfg/file_loader"
require "ucfg/env_expander"
require "ucfg/template_renderer"
require "ucfg/yaml_loader"
require "ucfg/config_merger"

module Ucfg
  class Error < StandardError; end

  def self.load_yaml(source, erb: false, env: false, env_parsers: {})
    raise Error, "ERB and environment expansion cannot be enabled together" if erb && env
    return YAMLLoader.load(source, env: env, env_parsers: env_parsers) unless erb

    rendered_source = TemplateRenderer.render(source, erb: erb)
    YAMLLoader.load(rendered_source)
  end

  def self.load(*paths, schema: nil, erb: false, env: false, env_parsers: {})
    result = load_result(*paths, schema: schema, erb: erb, env: env, env_parsers: env_parsers)
    return result.config if result.valid?

    raise Error, "Configuration load failed:\n- #{result.errors.join("\n- ")}"
  end

  class << self
    alias load! load
  end

  def self.load_result(*paths, schema: nil, erb: false, env: false, env_parsers: {})
    config = nil
    config = load_files(*paths, erb: erb, env: env, env_parsers: env_parsers)
    validation_schema = load_schema(schema)
    return LoadResult.new(config: config) if validation_schema.nil?

    validation = validate(config, validation_schema)
    LoadResult.new(config: config, errors: validation.errors)
  rescue Error => e
    LoadResult.new(config: config, errors: [e.message])
  end

  def self.load_file(path, erb: false, env: false, env_parsers: {})
    source = FileLoader.read(path)
    load_yaml(source, erb: erb, env: env, env_parsers: env_parsers)
  end

  def self.validate_file(path, schema, erb: false, env: false, env_parsers: {})
    config = load_file(path, erb: erb, env: env, env_parsers: env_parsers)
    validate(config, schema)
  end

  def self.load_files(*paths, erb: false, env: false, env_parsers: {})
    raise Error, "At least one file path must be provided" if paths.empty?

    paths.reduce({}) do |merged, path|
      loaded = load_file(path, erb: erb, env: env, env_parsers: env_parsers)
      ConfigMerger.merge(merged, loaded)
    end
  end

  def self.validate_yaml(source, schema, erb: false, env: false, env_parsers: {})
    validate(load_yaml(source, erb: erb, env: env, env_parsers: env_parsers), schema)
  end

  def self.validate(config, schema)
    result = JSONSchema.validate_recursively(config, schema, path: [])
    ValidationResult.from_json_schema_validation(result)
  end

  def self.load_schema(schema)
    return nil if schema.nil?
    return schema if schema.is_a?(Hash)

    load_file(schema)
  end
  private_class_method :load_schema
end
