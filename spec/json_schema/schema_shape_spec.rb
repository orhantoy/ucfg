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
end
