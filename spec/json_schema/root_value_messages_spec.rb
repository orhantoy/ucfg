# frozen_string_literal: true

RSpec.describe "root value error messages" do
  let(:cases) do
    {
      "type" => [
        "x",
        { "type" => "integer" },
        "Root value must be of type `integer` (provided value `x` of type `string`)",
      ],
      "enum" => [
        "x",
        { "enum" => %w[a b] },
        "Root value contains an unsupported value (provided `x`)",
      ],
      "const" => [
        "x",
        { "const" => "a" },
        "Root value must have value `a` (provided `x`)",
      ],
      "pattern" => [
        "x",
        { "pattern" => "^\\d+$" },
        "Root value must match pattern `^\\d+$` (provided `x`)",
      ],
      "minimum" => [
        1,
        { "minimum" => 5 },
        "Root value must be greater than or equal to 5 (provided 1)",
      ],
      "minLength" => [
        "a",
        { "minLength" => 3 },
        "Root value must have at least 3 characters (provided length 1)",
      ],
      "min/max" => [
        1,
        { "min" => 5, "max" => 9 },
        "Root value must be between 5 and 9 (provided 1)",
      ],
      "uniqueItems" => [
        [1, 1],
        { "uniqueItems" => true },
        "Root value must contain unique items",
      ],
      "anyOf" => [
        "x",
        { "anyOf" => [{ "type" => "integer" }] },
        "Root value must match at least one schema in `anyOf`",
      ],
      "oneOf" => [
        "x",
        { "oneOf" => [{ "type" => "integer" }, { "type" => "boolean" }] },
        "Root value must match exactly one schema in `oneOf` (matched 0)",
      ],
    }
  end

  it "names the root instead of rendering an empty property path" do
    aggregate_failures do
      cases.each do |keyword, (config, schema, message)|
        expect(Ucfg.validate(config, schema).errors).to eq([message]), "unexpected message for `#{keyword}`"
      end
    end
  end

  it "names the root for schema errors about an invalid pattern" do
    result = Ucfg.validate("x", { "pattern" => "[" })

    expect(result.errors).to eq(["Root value has invalid pattern `[` in schema (premature end of char-class: /[/)"])
  end

  it "still names the property path for nested values" do
    schema = { "properties" => { "service" => { "properties" => { "port" => { "type" => "integer" } } } } }

    result = Ucfg.validate({ "service" => { "port" => "http" } }, schema)

    expect(result.errors).to eq(["Property `service.port` must be of type `integer` (provided value `http` of type `string`)"])
  end
end
