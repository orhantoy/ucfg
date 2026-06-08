# frozen_string_literal: true

require "json"

RSpec.describe "JSON Schema composition keywords" do
  describe "anyOf" do
    it "passes when at least one subschema matches" do
      schema = {
        "properties" => {
          "value" => {
            "anyOf" => [
              { "type" => "string" },
              { "type" => "number" },
            ],
          },
        },
      }

      result = Ucfg.validate({ "value" => "text" }, schema)

      expect(result).to be_valid
      expect(result.errors).to eq([])
    end

    it "fails when no subschema matches" do
      schema = {
        "properties" => {
          "value" => {
            "anyOf" => [
              { "type" => "string" },
              { "type" => "number" },
            ],
          },
        },
      }

      result = Ucfg.validate({ "value" => true }, schema)

      expect(result.valid?).to eq(false)
      expect(result.errors).to eq(["Property `value` must match at least one schema in `anyOf`"])
    end

    it "rejects non-object subschemas" do
      schema = {
        "properties" => {
          "value" => {
            "anyOf" => [
              nil,
              "invalid",
              { "type" => "string" },
            ],
          },
        },
      }

      result = Ucfg.validate({ "value" => "text" }, schema)

      expect(result.errors).to eq(
        [
          "Schema keyword `value.anyOf.0` must be an object",
          "Schema keyword `value.anyOf.1` must be an object",
        ],
      )
    end
  end

  describe "oneOf" do
    it "passes when exactly one subschema matches" do
      schema = {
        "properties" => {
          "value" => {
            "oneOf" => [
              { "type" => "string" },
              { "type" => "number" },
            ],
          },
        },
      }

      result = Ucfg.validate({ "value" => 7 }, schema)

      expect(result).to be_valid
      expect(result.errors).to eq([])
    end

    it "fails when no subschema matches" do
      schema = {
        "properties" => {
          "value" => {
            "oneOf" => [
              { "type" => "string" },
              { "type" => "number" },
            ],
          },
        },
      }

      result = Ucfg.validate({ "value" => nil }, schema)

      expect(result.valid?).to eq(false)
      expect(result.errors).to eq(["Property `value` must match exactly one schema in `oneOf` (matched 0)"])
    end

    it "fails when more than one subschema matches" do
      schema = {
        "properties" => {
          "value" => {
            "oneOf" => [
              { "type" => "number" },
              { "min" => 0 },
            ],
          },
        },
      }

      result = Ucfg.validate({ "value" => 5 }, schema)

      expect(result.valid?).to eq(false)
      expect(result.errors).to eq(["Property `value` must match exactly one schema in `oneOf` (matched 2)"])
    end

    it "rejects non-object subschemas" do
      schema = {
        "properties" => {
          "value" => {
            "oneOf" => [
              nil,
              123,
              { "type" => "number" },
            ],
          },
        },
      }

      result = Ucfg.validate({ "value" => 7 }, schema)

      expect(result.errors).to eq(
        [
          "Schema keyword `value.oneOf.0` must be an object",
          "Schema keyword `value.oneOf.1` must be an object",
        ],
      )
    end
  end

  describe "allOf" do
    it "passes when all subschemas match" do
      schema = {
        "properties" => {
          "value" => {
            "allOf" => [
              { "type" => "number" },
              { "min" => 3 },
              { "max" => 8 },
            ],
          },
        },
      }

      result = Ucfg.validate({ "value" => 5 }, schema)

      expect(result).to be_valid
      expect(result.errors).to eq([])
    end

    it "fails when any subschema fails" do
      schema = {
        "properties" => {
          "value" => {
            "allOf" => [
              { "type" => "number" },
              { "min" => 3 },
            ],
          },
        },
      }

      result = Ucfg.validate({ "value" => 2 }, schema)

      expect(result.valid?).to eq(false)
      expect(result.errors).to eq(["Property `value` must be greater than or equal to 3 (provided 2)"])
    end

    it "rejects non-object subschemas" do
      schema = {
        "properties" => {
          "value" => {
            "allOf" => [
              nil,
              "invalid",
              { "type" => "number" },
              { "min" => 1 },
            ],
          },
        },
      }

      result = Ucfg.validate({ "value" => 2 }, schema)

      expect(result.errors).to eq(
        [
          "Schema keyword `value.allOf.0` must be an object",
          "Schema keyword `value.allOf.1` must be an object",
        ],
      )
    end
  end

  it "includes nested property paths in composition errors" do
    schema = {
      "properties" => {
        "parent" => {
          "properties" => {
            "child" => {
              "anyOf" => [
                { "type" => "string" },
                { "type" => "number" },
              ],
            },
          },
        },
      },
    }

    result = Ucfg.validate({ "parent" => { "child" => true } }, schema)

    expect(result.valid?).to eq(false)
    expect(result.errors).to eq(["Property `parent.child` must match at least one schema in `anyOf`"])
  end

  it "includes array item paths in composition errors" do
    schema = {
      "properties" => {
        "values" => {
          "type" => "array",
          "items" => {
            "oneOf" => [
              { "type" => "number" },
              { "type" => "string" },
            ],
          },
        },
      },
    }

    result = Ucfg.validate({ "values" => [1, true] }, schema)

    expect(result.valid?).to eq(false)
    expect(result.errors).to eq(["Property `values.1` must match exactly one schema in `oneOf` (matched 0)"])
  end
end
