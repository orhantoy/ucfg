# frozen_string_literal: true

require "json"

RSpec.describe "patternProperties" do
  it "still validates explicit properties" do
    config = <<-JSON
    {
      "name": true,
      "x-timeout": 30
    }
    JSON

    schema = <<-JSON
    {
      "properties": {
        "name": {
          "type": "string"
        }
      },
      "patternProperties": {
        "^x-": {
          "type": "number"
        }
      }
    }
    JSON

    result = Ucfg.validate(JSON.parse(config), JSON.parse(schema))

    expect(result.valid?).to eq(false)
    expect(result.errors).to eq(["Property `name` must be of type `string` (provided value `true` of type `boolean`)"])
  end

  it "validates keys matched by patternProperties" do
    config = <<-JSON
    {
      "service": {
        "x-timeout": "slow"
      }
    }
    JSON

    schema = <<-JSON
    {
      "properties": {
        "service": {
          "patternProperties": {
            "^x-": {
              "type": "number"
            }
          }
        }
      }
    }
    JSON

    result = Ucfg.validate(JSON.parse(config), JSON.parse(schema))

    expect(result.valid?).to eq(false)
    expect(result.errors).to eq(["Property `service.x-timeout` must be of type `number` (provided value `slow` of type `string`)"])
  end

  it "rejects extra properties when additionalProperties is false, except covered keys" do
    config = <<-JSON
    {
      "name": "ucfg",
      "x-timeout": 30,
      "other": "nope"
    }
    JSON

    schema = <<-JSON
    {
      "additionalProperties": false,
      "properties": {
        "name": {
          "type": "string"
        }
      },
      "patternProperties": {
        "^x-": {
          "type": "number"
        }
      }
    }
    JSON

    result = Ucfg.validate(JSON.parse(config), JSON.parse(schema))

    expect(result.valid?).to eq(false)
    expect(result.errors).to eq(["Property `other` is not supported"])
  end

  it "applies additionalProperties schema only to uncovered keys" do
    config = <<-JSON
    {
      "name": "ucfg",
      "x-enabled": true,
      "other": "nope"
    }
    JSON

    schema = <<-JSON
    {
      "additionalProperties": {
        "type": "number"
      },
      "properties": {
        "name": {
          "type": "string"
        }
      },
      "patternProperties": {
        "^x-": {
          "type": "boolean"
        }
      }
    }
    JSON

    result = Ucfg.validate(JSON.parse(config), JSON.parse(schema))

    expect(result.valid?).to eq(false)
    expect(result.errors).to eq(["Property `other` must be of type `number` (provided value `nope` of type `string`)"])
  end
end
