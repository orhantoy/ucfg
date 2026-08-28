# frozen_string_literal: true

RSpec.describe Ucfg::JSONSchema::ValidationContext do
  it "collects recursive validation errors in one context" do
    context = described_class.new
    schema = {
      "properties" => {
        "name" => { "type" => "string" },
        "port" => { "type" => "integer" },
      },
    }

    result = Ucfg::JSONSchema.validate_recursively(
      { "name" => true, "port" => "3000" },
      schema,
      path: [],
      context: context,
    )

    expect(result).to equal(context)
    expect(context.errors).to eq(
      [
        "Property `name` must be of type `string` (provided value `true` of type `boolean`)",
        "Property `port` must be of type `integer` (provided value `3000` of type `string`)",
      ],
    )
  end

  it "creates the public result at the validation boundary" do
    context = described_class.new
    context.add_schema_error(["properties"], "name", "must be an object")

    result = context.to_result

    expect(result).to be_a(Ucfg::ValidationResult)
    expect(result.error_details.first.type).to eq(:schema)
    expect(result.errors).to eq(["Schema keyword `properties.name` must be an object"])
  end
end
