# frozen_string_literal: true

require "open3"
require "rbconfig"

RSpec.describe "library load boundaries" do
  def run_ruby(source, warnings: false)
    warning_flag = warnings ? ["-w"] : []
    Open3.capture3(RbConfig.ruby, *warning_flag, "-Ilib", "-e", source)
  end

  it "loads the public entry point without circular require warnings" do
    _, stderr, status = run_ruby('require "ucfg"', warnings: true)

    expect(status).to be_success
    expect(stderr).not_to include("circular require")
  end

  it "loads error-raising components independently" do
    components = {
      "ucfg/config_merger" => "Ucfg::ConfigMerger.merge(1, {})",
      "ucfg/env_expander" => 'Ucfg::EnvExpander.expand("${MISSING}", env: {})',
      "ucfg/file_loader" => "Ucfg::FileLoader.read(123)",
      "ucfg/template_renderer" => "Ucfg::TemplateRenderer.render(123)",
      "ucfg/yaml_loader" => "Ucfg::YAMLLoader.load(123)",
    }

    components.each do |required_file, invocation|
      source = <<~RUBY
        require #{required_file.inspect}
        begin
          #{invocation}
        rescue Ucfg::Error
          exit 0
        end
        exit 1
      RUBY

      _, stderr, status = run_ruby(source)
      expect(status).to be_success, "#{required_file} failed to load independently: #{stderr}"
    end
  end

  it "loads recursive validators independently" do
    source = <<~'RUBY'
      require "ucfg/json_schema/properties"
      schema = { "properties" => { "name" => { "type" => "string" } } }
      result = Ucfg::JSONSchema::Properties.validate({ "name" => 1 }, schema, path: [])
      exit(result.errors.empty? ? 1 : 0)
    RUBY

    _, stderr, status = run_ruby(source, warnings: true)

    expect(status).to be_success
    expect(stderr).not_to include("circular require")
  end
end
