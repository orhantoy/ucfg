# frozen_string_literal: true

RSpec.describe "unsupported JSON Schema keywords" do
  # Every keyword the README documents as unsupported, paired with a value that
  # would change the outcome if the keyword were implemented.
  let(:unsupported_keywords) do
    {
      "$schema" => "https://json-schema.org/draft/2020-12/schema",
      "$id" => "https://example.test/schema",
      "$ref" => "#/$defs/thing",
      "$defs" => { "thing" => { "type" => "integer" } },
      "definitions" => { "thing" => { "type" => "integer" } },
      "default" => "fallback",
      "title" => "Service",
      "description" => "A service",
      "examples" => ["example"],
      "deprecated" => true,
      "readOnly" => true,
      "format" => "email",
      "multipleOf" => 2,
      "not" => { "type" => "object" },
      "if" => { "type" => "object" },
      "then" => { "required" => ["absent"] },
      "else" => { "required" => ["absent"] },
      "dependentRequired" => { "name" => ["absent"] },
      "dependentSchemas" => { "name" => { "required" => ["absent"] } },
      "dependencies" => { "name" => ["absent"] },
      "propertyNames" => { "minLength" => 99 },
      "minProperties" => 99,
      "maxProperties" => 0,
      "prefixItems" => [{ "type" => "boolean" }],
      "contains" => { "type" => "boolean" },
      "minContains" => 5,
      "maxContains" => 0,
      "unevaluatedProperties" => false,
      "unevaluatedItems" => false,
      "patternRequired" => ["^absent-"],
      "contentEncoding" => "base64",
      "contentMediaType" => "application/json",
      "contentSchema" => { "type" => "boolean" },
    }
  end

  it "ignores every keyword documented as unsupported" do
    aggregate_failures do
      unsupported_keywords.each do |keyword, value|
        result = Ucfg.validate({ "name" => "ucfg" }, { keyword => value })

        expect(result.errors).to eq([]), "expected `#{keyword}` to be ignored, got #{result.errors.inspect}"
      end
    end
  end

  it "keeps validating supported keywords alongside unsupported ones" do
    schema = unsupported_keywords.merge(
      "type" => "object",
      "required" => ["name"],
      "properties" => { "name" => { "type" => "string" } },
    )

    expect(Ucfg.validate({ "name" => "ucfg" }, schema)).to be_valid
    expect(Ucfg.validate({ "name" => 1 }, schema).errors).to eq(
      ["Property `name` must be of type `string` (provided value `1` of type `integer`)"],
    )
    expect(Ucfg.validate({}, schema).errors).to eq(["Required property `name` is missing"])
  end

  it "does not let an unsupported keyword reject an otherwise valid value" do
    schema = { "properties" => { "name" => { "type" => "string", "not" => { "type" => "string" } } } }

    expect(Ucfg.validate({ "name" => "ucfg" }, schema)).to be_valid
  end

  it "reports tuple-style items through the explicit items schema-shape check" do
    result = Ucfg.validate([1, 2], { "items" => [{ "type" => "string" }, { "type" => "string" }] })

    expect(result.errors).to eq(["Schema keyword `items` must be an object"])
    expect(result.error_details.first.type).to eq(:schema)
  end
end
