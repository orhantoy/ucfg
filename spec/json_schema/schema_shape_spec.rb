# frozen_string_literal: true

RSpec.describe "JSON Schema shape validation" do
  it "reports malformed root keyword shapes" do
    schema = {
      "required" => "name",
      "properties" => [],
    }

    result = Ucfg.validate({}, schema)

    expect(result.errors).to eq(
      [
        "Schema keyword `required` must be an array of property names",
        "Schema keyword `properties` must be an object",
      ],
    )
    expect(result.error_details.map(&:to_h)).to eq(
      [
        {
          message: "Schema keyword `required` must be an array of property names",
          path: [],
          keyword: "required",
          type: :schema,
        },
        {
          message: "Schema keyword `properties` must be an object",
          path: [],
          keyword: "properties",
          type: :schema,
        },
      ],
    )
  end

  it "reports malformed property subschemas even when the property is absent" do
    schema = {
      "properties" => {
        "service" => nil,
      },
    }

    result = Ucfg.validate({}, schema)

    expect(result.errors).to eq(["Schema keyword `properties.service` must be an object"])
  end

  it "reports malformed items and additionalProperties schemas" do
    schema = {
      "additionalProperties" => "no",
      "items" => [],
    }

    result = Ucfg.validate([], schema)

    expect(result.errors).to eq(
      [
        "Schema keyword `additionalProperties` must be a boolean or object",
        "Schema keyword `items` must be an object",
      ],
    )
  end

  it "reports malformed patternProperties subschemas at the pattern path" do
    schema = {
      "patternProperties" => {
        "^x-" => nil,
      },
    }

    result = Ucfg.validate({}, schema)

    expect(result.errors).to eq(["Schema keyword `patternProperties.^x-` must be an object"])
  end

  it "reports malformed keyword shapes against the offending keyword path" do
    cases = {
      { "enum" => "red" } => "Schema keyword `a.enum` must be an array",
      { "uniqueItems" => "yes" } => "Schema keyword `a.uniqueItems` must be a boolean",
      { "minLength" => -1 } => "Schema keyword `a.minLength` must be a non-negative integer",
      { "maxLength" => 1.5 } => "Schema keyword `a.maxLength` must be a non-negative integer",
      { "minItems" => "2" } => "Schema keyword `a.minItems` must be a non-negative integer",
      { "maxItems" => -3 } => "Schema keyword `a.maxItems` must be a non-negative integer",
      { "pattern" => 123 } => "Schema keyword `a.pattern` must be a string",
      { "anyOf" => {} } => "Schema keyword `a.anyOf` must be an array of schemas",
      { "oneOf" => "x" } => "Schema keyword `a.oneOf` must be an array of schemas",
      { "allOf" => nil } => "Schema keyword `a.allOf` must be an array of schemas",
      { "minimum" => "1" } => "Schema keyword `a.minimum` must be a number",
      { "type" => "stringy" } => "Schema keyword `a.type` must be a supported JSON Schema type or an array of supported types",
    }

    aggregate_failures do
      cases.each do |subschema, message|
        result = Ucfg.validate({ "a" => "value" }, { "properties" => { "a" => subschema } })

        expect(result.errors).to eq([message]), "unexpected errors for #{subschema.inspect}: #{result.errors.inspect}"
        expect(result.error_details.first.type).to eq(:schema)
      end
    end
  end

  it "rejects required entries that are not property names" do
    result = Ucfg.validate({}, { "required" => ["name", 1] })

    expect(result.errors).to eq(["Schema keyword `required` must contain only property names"])
    expect(result.error_details.first.type).to eq(:schema)
  end

  it "reports a root schema that is not an object" do
    ["nope", [], nil, 7].each do |schema|
      result = Ucfg.validate({ "a" => 1 }, schema)

      expect(result.errors).to eq(["Schema keyword `schema` must be an object"])
      expect(result.error_details.first.type).to eq(:schema)
    end
  end

  it "keeps validating sibling keywords after a shape error" do
    schema = { "properties" => { "a" => { "enum" => "red", "type" => "string" } } }

    expect(Ucfg.validate({ "a" => 1 }, schema).errors).to eq(
      [
        "Schema keyword `a.enum` must be an array",
        "Property `a` must be of type `string` (provided value `1` of type `integer`)",
      ],
    )
  end

  it "only reaches subschema shape errors when the property is present" do
    schema = { "properties" => { "a" => { "enum" => "red" } } }

    expect(Ucfg.validate({}, schema)).to be_valid
    expect(Ucfg.validate({ "a" => "value" }, schema).errors).to eq(["Schema keyword `a.enum` must be an array"])
  end
end
