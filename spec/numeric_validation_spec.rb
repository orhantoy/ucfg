# frozen_string_literal: true

require "json"

RSpec.describe "Numeric validation" do
  it "supports minimum" do
    schema = <<-JSON
    {
      "properties": {
        "a": {
          "min": 3
        }
      }
    }
    JSON
    schema_as_hash = JSON.parse(schema)

    expect(Ucfg.validate({ "a" => 3 }, schema_as_hash)).to be_valid
    expect(Ucfg.validate({ "a" => 4 }, schema_as_hash)).to be_valid
    expect(Ucfg.validate({ "a" => 2 }, schema_as_hash).errors).to eq(["Property `a` must be greater than or equal to 3 (provided 2)"])
  end

  it "supports maximum" do
    schema = <<-JSON
    {
      "properties": {
        "a": {
          "max": 3
        }
      }
    }
    JSON
    schema_as_hash = JSON.parse(schema)

    expect(Ucfg.validate({ "a" => 2 }, schema_as_hash)).to be_valid
    expect(Ucfg.validate({ "a" => 3 }, schema_as_hash)).to be_valid
    expect(Ucfg.validate({ "a" => 4 }, schema_as_hash).errors).to eq(["Property `a` must be less than or equal to 3 (provided 4)"])
  end

  it "supports range" do
    schema = <<-JSON
    {
      "properties": {
        "a": {
          "min": -20,
          "max": 3
        }
      }
    }
    JSON
    schema_as_hash = JSON.parse(schema)

    expect(Ucfg.validate({ "a" => -10 }, schema_as_hash)).to be_valid
    expect(Ucfg.validate({ "a" => 3 }, schema_as_hash)).to be_valid
    expect(Ucfg.validate({ "a" => 4 }, schema_as_hash).errors).to eq(["Property `a` must be between -20 and 3 (provided 4)"])
  end
end
