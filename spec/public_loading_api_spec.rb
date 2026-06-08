# frozen_string_literal: true

require "tmpdir"

RSpec.describe Ucfg do
  describe ".load_yaml" do
    it "parses YAML without ERB rendering by default" do
      source = <<~YAML
        api_key: <%= ENV["PUBLIC_LOADING_API_KEY"] %>
      YAML

      expect(described_class.load_yaml(source)).to eq(
        "api_key" => '<%= ENV["PUBLIC_LOADING_API_KEY"] %>',
      )
    end

    it "renders ERB before parsing when erb is enabled" do
      with_env("PUBLIC_LOADING_API_KEY", "secret-token") do
        source = <<~YAML
          api_key: <%= ENV["PUBLIC_LOADING_API_KEY"] %>
        YAML

        expect(described_class.load_yaml(source, erb: true)).to eq(
          "api_key" => "secret-token",
        )
      end
    end

    it "keeps YAMLLoader non-string error behavior when ERB is disabled" do
      expect { described_class.load_yaml(123) }
        .to raise_error(Ucfg::Error, /YAML source must be a string/i)
    end
  end

  describe ".load_file" do
    it "loads file content without ERB rendering by default" do
      Dir.mktmpdir do |dir|
        path = File.join(dir, "config.yml")
        File.write(path, "api_key: <%= ENV[\"PUBLIC_LOADING_API_FILE_KEY\"] %>\n")

        expect(described_class.load_file(path)).to eq(
          "api_key" => '<%= ENV["PUBLIC_LOADING_API_FILE_KEY"] %>',
        )
      end
    end

    it "renders ERB in file content when erb is enabled" do
      with_env("PUBLIC_LOADING_API_FILE_KEY", "file-secret") do
        Dir.mktmpdir do |dir|
          path = File.join(dir, "config.yml")
          File.write(path, "api_key: <%= ENV[\"PUBLIC_LOADING_API_FILE_KEY\"] %>\n")

          expect(described_class.load_file(path, erb: true)).to eq(
            "api_key" => "file-secret",
          )
        end
      end
    end
  end

  describe ".validate_file" do
    it "loads and validates file content" do
      Dir.mktmpdir do |dir|
        path = File.join(dir, "config.yml")
        File.write(path, "service.enabled: true\n")

        schema = {
          "properties" => {
            "service" => {
              "required" => ["enabled"],
              "properties" => {
                "enabled" => { "type" => "boolean" },
              },
            },
          },
        }

        result = described_class.validate_file(path, schema)

        expect(result).to be_valid
        expect(result.errors).to eq([])
      end
    end
  end

  describe ".validate_yaml" do
    it "remains compatible with callers that do not pass options" do
      source = <<~YAML
        service.name: ucfg
      YAML

      schema = {
        "properties" => {
          "service" => {
            "required" => ["name"],
            "properties" => {
              "name" => { "type" => "string" },
            },
          },
        },
      }

      result = described_class.validate_yaml(source, schema)

      expect(result).to be_valid
      expect(result.errors).to eq([])
    end

    it "keeps non-string source errors compatible" do
      expect { described_class.validate_yaml(123, {}) }
        .to raise_error(Ucfg::Error, /YAML source must be a string/i)
    end
  end

  def with_env(key, value)
    original = ENV[key]
    ENV[key] = value
    yield
  ensure
    if original.nil?
      ENV.delete(key)
    else
      ENV[key] = original
    end
  end
end
