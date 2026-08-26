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
          :message => "Schema keyword `required` must be an array of property names",
          :path => [],
          :keyword => "required",
          :type => :schema,
        },
        {
          :message => "Schema keyword `properties` must be an object",
          :path => [],
          :keyword => "properties",
          :type => :schema,
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
end
