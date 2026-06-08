# frozen_string_literal: true

require "json"

RSpec.describe "Numeric validation" do
  it "supports min" do
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

  it "supports minimum alias" do
    schema = <<-JSON
    {
      "properties": {
        "a": {
          "minimum": 3
        }
      }
    }
    JSON
    schema_as_hash = JSON.parse(schema)

    expect(Ucfg.validate({ "a" => 3 }, schema_as_hash)).to be_valid
    expect(Ucfg.validate({ "a" => 4 }, schema_as_hash)).to be_valid
    expect(Ucfg.validate({ "a" => 2 }, schema_as_hash).errors).to eq(["Property `a` must be greater than or equal to 3 (provided 2)"])
  end

  it "supports max" do
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

  it "supports maximum alias" do
    schema = <<-JSON
    {
      "properties": {
        "a": {
          "maximum": 3
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

  it "validates both min and minimum when both are present" do
    schema = <<-JSON
    {
      "properties": {
        "a": {
          "min": 1,
          "minimum": 3
        }
      }
    }
    JSON
    schema_as_hash = JSON.parse(schema)

    expect(Ucfg.validate({ "a" => 3 }, schema_as_hash)).to be_valid
    expect(Ucfg.validate({ "a" => 2 }, schema_as_hash).errors).to eq(["Property `a` must be greater than or equal to 3 (provided 2)"])
    expect(Ucfg.validate({ "a" => 0 }, schema_as_hash).errors).to eq(
      [
        "Property `a` must be greater than or equal to 1 (provided 0)",
        "Property `a` must be greater than or equal to 3 (provided 0)",
      ],
    )
  end

  it "validates both max and maximum when both are present" do
    schema = <<-JSON
    {
      "properties": {
        "a": {
          "max": 8,
          "maximum": 3
        }
      }
    }
    JSON
    schema_as_hash = JSON.parse(schema)

    expect(Ucfg.validate({ "a" => 3 }, schema_as_hash)).to be_valid
    expect(Ucfg.validate({ "a" => 5 }, schema_as_hash).errors).to eq(["Property `a` must be less than or equal to 3 (provided 5)"])
    expect(Ucfg.validate({ "a" => 9 }, schema_as_hash).errors).to eq(
      [
        "Property `a` must be less than or equal to 8 (provided 9)",
        "Property `a` must be less than or equal to 3 (provided 9)",
      ],
    )
  end

  it "ignores minimum and maximum when instance is not numeric" do
    schema = <<-JSON
    {
      "properties": {
        "a": {
          "minimum": 1,
          "maximum": 2
        }
      }
    }
    JSON
    schema_as_hash = JSON.parse(schema)

    expect(Ucfg.validate({ "a" => "text" }, schema_as_hash)).to be_valid
  end

  it "ignores invalid minimum and maximum schema values" do
    schema = <<-JSON
    {
      "properties": {
        "a": {
          "minimum": "1",
          "maximum": null
        }
      }
    }
    JSON
    schema_as_hash = JSON.parse(schema)

    expect(Ucfg.validate({ "a" => 99 }, schema_as_hash)).to be_valid
  end
end
