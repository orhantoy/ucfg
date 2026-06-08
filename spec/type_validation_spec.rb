# frozen_string_literal: true

require "json"

RSpec.describe "Type validation" do
  it "supports multiple types" do
    schema = <<-JSON
    {
      "properties": {
        "name": {
          "type": ["string", "boolean"]
        }
      }
    }
    JSON
    schema_as_hash = JSON.parse(schema)

    expect(Ucfg.validate({ "name" => "this is a string value" }, schema_as_hash)).to be_valid
    expect(Ucfg.validate({ "name" => true }, schema_as_hash)).to be_valid
    expect(Ucfg.validate({ "name" => nil }, schema_as_hash).errors).to eq(["Property `name` must be of type `string` or `boolean` (provided `null`)"])
  end

  it "supports all types" do
    schema = <<-JSON
    {
      "properties": {
        "key_string": { "type": "string" },
        "key_boolean": { "type": "boolean" },
        "key_number": { "type": "number" },
        "key_integer": { "type": "integer" },
        "key_null": { "type": "null" },
        "key_object": { "type": "object" },
        "key_array": { "type": "array" },
        "key_invalid_type": { "type": "string_and_boolean" }
      }
    }
    JSON
    schema_as_hash = JSON.parse(schema)

    expect(Ucfg.validate({ "key_string" => "string value" }, schema_as_hash)).to be_valid
    expect(Ucfg.validate({ "key_boolean" => false }, schema_as_hash)).to be_valid
    expect(Ucfg.validate({ "key_number" => false }, schema_as_hash)).to_not be_valid
    expect(Ucfg.validate({ "key_number" => nil }, schema_as_hash)).to_not be_valid
    expect(Ucfg.validate({ "key_number" => 123 }, schema_as_hash)).to be_valid
    expect(Ucfg.validate({ "key_integer" => 123 }, schema_as_hash)).to be_valid
    expect(Ucfg.validate({ "key_integer" => 1.5 }, schema_as_hash).errors).to eq(["Property `key_integer` must be of type `integer` (provided value `1.5` of type `number`)"])
    expect(Ucfg.validate({ "key_null" => false }, schema_as_hash)).to_not be_valid
    expect(Ucfg.validate({ "key_null" => nil }, schema_as_hash)).to be_valid
    expect(Ucfg.validate({ "key_object" => {} }, schema_as_hash)).to be_valid
    expect(Ucfg.validate({ "key_array" => ["hey"] }, schema_as_hash)).to be_valid
    expect(Ucfg.validate({ "key_array" => {} }, schema_as_hash)).to_not be_valid
    expect(Ucfg.validate({ "key_invalid_type" => "value" }, schema_as_hash).errors).to eq(["Schema keyword `key_invalid_type.type` must be a supported JSON Schema type or an array of supported types"])
  end
end
