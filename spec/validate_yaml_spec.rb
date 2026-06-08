# frozen_string_literal: true

RSpec.describe Ucfg do
  describe ".validate_yaml" do
    it "loads yaml and validates it" do
      yaml = <<~YAML
        service.name: ucfg
        service.enabled: true
      YAML

      schema = {
        "properties" => {
          "service" => {
            "required" => ["name", "enabled"],
            "properties" => {
              "name" => { "type" => "string" },
              "enabled" => { "type" => "boolean" },
            },
          },
        },
      }

      result = described_class.validate_yaml(yaml, schema)

      expect(result).to be_valid
      expect(result.errors).to eq([])
    end

    it "surfaces validation errors after loading yaml" do
      yaml = <<~YAML
        service.name: ucfg
        service.enabled: nope
      YAML

      schema = {
        "properties" => {
          "service" => {
            "required" => ["name", "enabled"],
            "properties" => {
              "name" => { "type" => "string" },
              "enabled" => { "type" => "boolean" },
            },
          },
        },
      }

      result = described_class.validate_yaml(yaml, schema)

      expect(result.valid?).to eq(false)
      expect(result.errors).to eq(["Property `service.enabled` must be of type `boolean` (provided value `nope` of type `string`)"])
    end

    it "surfaces yaml parsing errors" do
      yaml = <<~YAML
        items: [one, two]
      YAML

      expect { described_class.validate_yaml(yaml, {}) }.to raise_error(Ucfg::Error, /flow style/i)
    end

    it "validates yaml after ERB rendering" do
      yaml = "service.enabled: <%= ENV['SERVICE_ENABLED'] %>"
      schema = { "properties" => { "service" => { "properties" => { "enabled" => { "type" => "boolean" } } } } }

      with_env("SERVICE_ENABLED", "true") do
        result = described_class.validate_yaml(yaml, schema, erb: true)

        expect(result).to be_valid
      end
    end

    it "validates yaml after environment expansion" do
      yaml = <<~YAML
        service.enabled: ${SERVICE_ENABLED:false}
        service.replicas: ${SERVICE_REPLICAS:3}
        service.hosts: ${SERVICE_HOSTS:host1:9200,host2:9200}
        service.name: app-${SERVICE_ENV:dev}
      YAML
      schema = {
        "properties" => {
          "service" => {
            "properties" => {
              "enabled" => { "type" => "boolean" },
              "replicas" => { "type" => "number" },
              "hosts" => { "type" => "array", "items" => { "type" => "string" } },
              "name" => { "const" => "app-prod" },
            },
          },
        },
      }

      with_env("SERVICE_ENABLED", "true") do
        with_env("SERVICE_ENV", "prod") do
          result = described_class.validate_yaml(yaml, schema, env: true)

          expect(result).to be_valid
        end
      end
    end

    it "does not expand environment values unless enabled" do
      yaml = "service.enabled: ${SERVICE_ENABLED:true}"
      schema = { "properties" => { "service" => { "properties" => { "enabled" => { "type" => "boolean" } } } } }

      result = described_class.validate_yaml(yaml, schema)

      expect(result.errors).to eq(["Property `service.enabled` must be of type `boolean` (provided value `${SERVICE_ENABLED:true}` of type `string`)"])
    end

    it "does not allow ERB and environment expansion at the same time" do
      expect { described_class.validate_yaml("value: true", {}, erb: true, env: true) }
        .to raise_error(Ucfg::Error, /cannot be enabled together/i)
    end
  end

  def with_env(key, value)
    original = ENV[key]

    if value.nil?
      ENV.delete(key)
    else
      ENV[key] = value
    end

    yield
  ensure
    if original.nil?
      ENV.delete(key)
    else
      ENV[key] = original
    end
  end
end
