# frozen_string_literal: true

require "json"

RSpec.describe "String and array validation" do
  it "supports minLength, maxLength and pattern for strings" do
    schema = <<-JSON
    {
      "properties": {
        "name": {
          "type": "string",
          "minLength": 3,
          "maxLength": 5,
          "pattern": "^[a-z]+$"
        }
      }
    }
    JSON
    schema_as_hash = JSON.parse(schema)

    expect(Ucfg.validate({ "name" => "abc" }, schema_as_hash)).to be_valid
    expect(Ucfg.validate({ "name" => "abcdef" }, schema_as_hash).errors).to eq(["Property `name` must have at most 5 characters (provided length 6)"])
    expect(Ucfg.validate({ "name" => "ab" }, schema_as_hash).errors).to eq(["Property `name` must have at least 3 characters (provided length 2)"])
    expect(Ucfg.validate({ "name" => "abc1" }, schema_as_hash).errors).to eq(["Property `name` must match pattern `^[a-z]+$` (provided `abc1`)"])
  end

  it "ignores string keywords for non-string values" do
    schema = <<-JSON
    {
      "properties": {
        "name": {
          "type": "number",
          "minLength": 3,
          "maxLength": 5,
          "pattern": "^[a-z]+$"
        }
      }
    }
    JSON
    schema_as_hash = JSON.parse(schema)

    expect(Ucfg.validate({ "name" => 12 }, schema_as_hash)).to be_valid
  end

  it "supports minItems, maxItems and uniqueItems for arrays" do
    schema = <<-JSON
    {
      "properties": {
        "tags": {
          "type": "array",
          "minItems": 2,
          "maxItems": 3,
          "uniqueItems": true
        }
      }
    }
    JSON
    schema_as_hash = JSON.parse(schema)

    expect(Ucfg.validate({ "tags" => %w[a b] }, schema_as_hash)).to be_valid
    expect(Ucfg.validate({ "tags" => ["a"] }, schema_as_hash).errors).to eq(["Property `tags` must contain at least 2 items (provided 1)"])
    expect(Ucfg.validate({ "tags" => %w[a b c d] }, schema_as_hash).errors).to eq(["Property `tags` must contain at most 3 items (provided 4)"])
    expect(Ucfg.validate({ "tags" => %w[a a] }, schema_as_hash).errors).to eq(["Property `tags` must contain unique items"])
  end

  it "ignores array keywords for non-array values" do
    schema = <<-JSON
    {
      "properties": {
        "tags": {
          "type": "string",
          "minItems": 2,
          "maxItems": 3,
          "uniqueItems": true
        }
      }
    }
    JSON
    schema_as_hash = JSON.parse(schema)

    expect(Ucfg.validate({ "tags" => "abc" }, schema_as_hash)).to be_valid
  end

  it "includes nested property path and array index path in errors" do
    schema = <<-JSON
    {
      "properties": {
        "service": {
          "properties": {
            "name": {
              "type": "string",
              "minLength": 4
            },
            "aliases": {
              "type": "array",
              "items": {
                "type": "string",
                "minLength": 3
              }
            }
          }
        }
      }
    }
    JSON
    schema_as_hash = JSON.parse(schema)

    expect(Ucfg.validate({ "service" => { "name" => "api", "aliases" => %w[main x] } }, schema_as_hash).errors).to eq([
                                                                                                                        "Property `service.name` must have at least 4 characters (provided length 3)",
                                                                                                                        "Property `service.aliases.1` must have at least 3 characters (provided length 1)",
                                                                                                                      ])
  end

  it "fails gracefully for invalid pattern definitions in schema" do
    schema = <<-JSON
    {
      "properties": {
        "name": {
          "type": "string",
          "pattern": "["
        }
      }
    }
    JSON
    schema_as_hash = JSON.parse(schema)

    expect(Ucfg.validate({ "name" => "abc" }, schema_as_hash).errors).to match([a_string_starting_with("Property `name` has invalid pattern `[` in schema (")])
  end
end
