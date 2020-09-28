# frozen_string_literal: true

require "json"
require "ucfg/json_schema"

RSpec.describe "items" do
  it "supports items with schema" do
    expect(Ucfg::JSONSchema.validate_recursively([1, 2, 3, 4, 5], { "items" => { "type" => "number" } }, path: ["key"])).to eq(:validation_errors => [])
    expect(Ucfg::JSONSchema.validate_recursively([1, 2, "3", 4, 5], { "items" => { "type" => "number" } }, path: ["key"])).to eq(:validation_errors => ["Property `key.2` must be of type `number` (provided value `3` of type `string`)"])
    expect(Ucfg::JSONSchema.validate_recursively([], { "items" => { "type" => "number" } }, path: ["key"])).to eq(:validation_errors => [])
  end
end
