# frozen_string_literal: true

require "json"

RSpec.describe "Type validation" do
  xit "supports multiple types" do
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

  xit "supports all types" do
    schema = <<-JSON
    {
      "properties": {
        "key_string": { "type": "string" },
        "key_boolean": { "type": "boolean" },
        "key_number": { "type": "number" },
        "key_null": { "type": "null" },
        "key_object": { "type": "object" },
        "key_array": { "type": "array" }
      }
    }
    JSON
    schema_as_hash = JSON.parse(schema)

    expect(Ucfg.validate({ "key_string" => "string value" }, schema_as_hash)).to be_valid
    expect(Ucfg.validate({ "key_boolean" => false }, schema_as_hash)).to be_valid
    expect(Ucfg.validate({ "key_number" => false }, schema_as_hash)).to_not be_valid
    expect(Ucfg.validate({ "key_number" => 123 }, schema_as_hash)).to be_valid
    expect(Ucfg.validate({ "key_null" => false }, schema_as_hash)).to_not be_valid
    expect(Ucfg.validate({ "key_null" => nil }, schema_as_hash)).to be_valid
    expect(Ucfg.validate({ "key_object" => {} }, schema_as_hash)).to be_valid
    expect(Ucfg.validate({ "key_array" => ["hey"] }, schema_as_hash)).to be_valid
    expect(Ucfg.validate({ "key_array" => {} }, schema_as_hash)).to_not be_valid
  end
end
