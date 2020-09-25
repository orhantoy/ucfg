# frozen_string_literal: true

require "json"

RSpec.describe "Enum validation" do
  it "supports string enum check" do
    schema = <<-JSON
    {
      "properties": {
        "color": {
          "type": "string",
          "enum": ["red", "green", "blue"]
        }
      }
    }
    JSON
    schema_as_hash = JSON.parse(schema)

    expect(Ucfg.validate({ "color" => "red" }, schema_as_hash)).to be_valid
    expect(Ucfg.validate({ "color" => "blue" }, schema_as_hash)).to be_valid
    expect(Ucfg.validate({ "color" => "yellow" }, schema_as_hash).errors).to eq(["Property `color` contains an unsupported value (provided `yellow`)"])
  end

  it "supports mixed value enum check" do
    schema = <<-JSON
    {
      "properties": {
        "name": {
          "enum": ["true", true]
        }
      }
    }
    JSON
    schema_as_hash = JSON.parse(schema)

    expect(Ucfg.validate({ "name" => "true" }, schema_as_hash)).to be_valid
    expect(Ucfg.validate({ "name" => true }, schema_as_hash)).to be_valid
    expect(Ucfg.validate({ "name" => "false" }, schema_as_hash).errors).to eq(["Property `name` contains an unsupported value (provided `false`)"])
  end

  it "supports const" do
    schema = <<-JSON
    {
      "properties": {
        "color": {
          "type": "string",
          "const": "red"
        }
      }
    }
    JSON
    schema_as_hash = JSON.parse(schema)

    expect(Ucfg.validate({ "color" => "red" }, schema_as_hash)).to be_valid
    expect(Ucfg.validate({ "color" => "yellow" }, schema_as_hash).errors).to eq(["Property `color` must have value `red` (provided `yellow`)"])
  end
end
