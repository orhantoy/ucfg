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
  end
end
