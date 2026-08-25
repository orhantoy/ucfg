# frozen_string_literal: true

require "tmpdir"

RSpec.describe Ucfg do
  describe ".load" do
    it "raises when no paths are provided" do
      expect { described_class.load }
        .to raise_error(Ucfg::Error, /At least one file path must be provided/)
    end

    it "loads and merges multiple files with later files overriding earlier files" do
      Dir.mktmpdir do |dir|
        base = File.join(dir, "base.yml")
        override = File.join(dir, "override.yml")

        File.write(base, <<~YAML)
          service:
            host: localhost
            port: 3000
          features:
            - base
        YAML

        File.write(override, <<~YAML)
          service:
            port: 9292
          features:
            - override
        YAML

        expect(described_class.load(base, override)).to eq(
          "service" => {
            "host" => "localhost",
            "port" => 9292,
          },
          "features" => ["override"],
        )
      end
    end

    it "validates the loaded config with a schema hash before returning it" do
      Dir.mktmpdir do |dir|
        path = File.join(dir, "config.yml")
        File.write(path, "service.enabled: true\n")

        schema = {
          "required" => ["service"],
          "properties" => {
            "service" => {
              "required" => ["enabled"],
              "properties" => {
                "enabled" => { "type" => "boolean" },
              },
            },
          },
        }

        expect(described_class.load(path, schema: schema)).to eq(
          "service" => { "enabled" => true },
        )
      end
    end

    it "treats string schemas as file paths, not raw YAML" do
      Dir.mktmpdir do |dir|
        config_path = File.join(dir, "config.yml")
        schema_path = File.join(dir, "schema.yml")

        File.write(config_path, "service.enabled: true\n")
        File.write(schema_path, <<~YAML)
          properties:
            service:
              required:
                - enabled
              properties:
                enabled:
                  type: boolean
        YAML

        expect(described_class.load(config_path, schema: schema_path)).to eq(
          "service" => { "enabled" => true },
        )
      end
    end

    it "treats path-like schemas as file paths" do
      Dir.mktmpdir do |dir|
        config_path = File.join(dir, "config.yml")
        schema_path = File.join(dir, "schema.yml")
        schema_path_like = Struct.new(:path) do
          def to_path
            path
          end
        end.new(schema_path)

        File.write(config_path, "service.enabled: true\n")
        File.write(schema_path, <<~YAML)
          properties:
            service:
              properties:
                enabled:
                  type: boolean
        YAML

        expect(described_class.load(config_path, schema: schema_path_like)).to eq(
          "service" => { "enabled" => true },
        )
      end
    end

    it "does not support raw YAML schema strings" do
      Dir.mktmpdir do |dir|
        config_path = File.join(dir, "config.yml")
        File.write(config_path, "service.enabled: true\n")

        raw_yaml_schema = <<~YAML
          properties:
            service:
              properties:
                enabled:
                  type: boolean
        YAML

        expect { described_class.load(config_path, schema: raw_yaml_schema) }
          .to raise_error(Ucfg::Error, /Failed to read file/)
      end
    end

    it "raises when a schema path cannot be read" do
      Dir.mktmpdir do |dir|
        config_path = File.join(dir, "config.yml")
        File.write(config_path, "name: ucfg\n")

        expect { described_class.load(config_path, schema: File.join(dir, "missing-schema.yml")) }
          .to raise_error(Ucfg::Error, /Failed to read file/)
      end
    end

    it "raises Ucfg::Error with validation errors when validation fails" do
      Dir.mktmpdir do |dir|
        path = File.join(dir, "config.yml")
        File.write(path, "service.enabled: nope\n")

        schema = {
          "properties" => {
            "service" => {
              "properties" => {
                "enabled" => { "type" => "boolean" },
              },
            },
          },
        }

        expect { described_class.load(path, schema: schema) }
          .to raise_error(
            Ucfg::Error,
            /Configuration load failed:\n- Property `service.enabled` must be of type `boolean`/,
          )
      end
    end

    it "passes env expansion through to every loaded file" do
      with_env("PUBLIC_LOADING_API_HOST", "example.test") do
        Dir.mktmpdir do |dir|
          first = File.join(dir, "first.yml")
          second = File.join(dir, "second.yml")

          File.write(first, "service.host: ${PUBLIC_LOADING_API_HOST}\n")
          File.write(second, "service.port: 443\n")

          expect(described_class.load(first, second, env: true)).to eq(
            "service" => {
              "host" => "example.test",
              "port" => 443,
            },
          )
        end
      end
    end

    it "passes environment parsers through to every loaded file" do
      with_env("PUBLIC_LOADING_API_HOSTS", "one.example,two.example") do
        Dir.mktmpdir do |dir|
          path = File.join(dir, "config.yml")
          File.write(path, "service.hosts: ${PUBLIC_LOADING_API_HOSTS}\n")

          expect(described_class.load(path, env: true, env_parsers: { "PUBLIC_LOADING_API_HOSTS" => :csv })).to eq(
            "service" => {
              "hosts" => ["one.example", "two.example"],
            },
          )
        end
      end
    end

    it "passes ERB rendering through to every loaded file" do
      with_env("PUBLIC_LOADING_API_ERB_PORT", "443") do
        Dir.mktmpdir do |dir|
          path = File.join(dir, "config.yml")
          File.write(path, "service.port: <%= ENV['PUBLIC_LOADING_API_ERB_PORT'] %>\n")

          expect(described_class.load(path, erb: true)).to eq(
            "service" => { "port" => 443 },
          )
        end
      end
    end

    it "raises when ERB and environment expansion are both enabled" do
      Dir.mktmpdir do |dir|
        path = File.join(dir, "config.yml")
        File.write(path, "name: ucfg\n")

        expect { described_class.load(path, erb: true, env: true) }
          .to raise_error(Ucfg::Error, /ERB and environment expansion cannot be enabled together/)
      end
    end
  end

  describe ".load!" do
    it "is the strict raising loader" do
      expect(described_class.method(:load!)).to eq(described_class.method(:load))
    end
  end

  describe ".load_result" do
    it "returns an error result when no paths are provided" do
      result = described_class.load_result

      expect(result).not_to be_valid
      expect(result.config).to be_nil
      expect(result.errors).to eq(["At least one file path must be provided"])
    end

    it "returns a valid result with the loaded config" do
      Dir.mktmpdir do |dir|
        path = File.join(dir, "config.yml")
        File.write(path, "name: ucfg\n")

        result = described_class.load_result(path)

        expect(result).to be_valid
        expect(result.config).to eq("name" => "ucfg")
        expect(result.errors).to eq([])
      end
    end

    it "returns validation errors without raising and keeps the loaded config" do
      Dir.mktmpdir do |dir|
        path = File.join(dir, "config.yml")
        File.write(path, "service.enabled: nope\n")

        schema = {
          "properties" => {
            "service" => {
              "properties" => {
                "enabled" => { "type" => "boolean" },
              },
            },
          },
        }

        result = described_class.load_result(path, schema: schema)

        expect(result).not_to be_valid
        expect(result.config).to eq("service" => { "enabled" => "nope" })
        expect(result.errors).to eq([
                                      "Property `service.enabled` must be of type `boolean` (provided value `nope` of type `string`)",
                                    ])
      end
    end

    it "returns loader errors without raising" do
      result = described_class.load_result("/path/that/does/not/exist.yml")

      expect(result).not_to be_valid
      expect(result.config).to be_nil
      expect(result.errors.first).to match(/Failed to read file/)
    end

    it "keeps the loaded config when schema loading fails" do
      Dir.mktmpdir do |dir|
        path = File.join(dir, "config.yml")
        File.write(path, "name: ucfg\n")

        result = described_class.load_result(path, schema: File.join(dir, "missing-schema.yml"))

        expect(result).not_to be_valid
        expect(result.config).to eq("name" => "ucfg")
        expect(result.errors.first).to match(/Failed to read file/)
      end
    end

    it "returns an error result when ERB and environment expansion are both enabled" do
      Dir.mktmpdir do |dir|
        path = File.join(dir, "config.yml")
        File.write(path, "name: ucfg\n")

        result = described_class.load_result(path, erb: true, env: true)

        expect(result).not_to be_valid
        expect(result.config).to be_nil
        expect(result.errors).to eq(["ERB and environment expansion cannot be enabled together"])
      end
    end
  end

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
