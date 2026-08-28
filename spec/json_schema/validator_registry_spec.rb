# frozen_string_literal: true

RSpec.describe Ucfg::JSONSchema::ValidatorRegistry do
  def validator_for(*keywords)
    Class.new(Ucfg::JSONSchema::Validator) do
      handles(*keywords)

      def self.validate(_instance, _schema, path:, context:)
        context
      end
    end
  end

  it "selects matching strategies in registration order" do
    type_validator = validator_for("type")
    range_validator = validator_for("minimum", "maximum")
    properties_validator = validator_for("properties")
    registry = described_class.new([range_validator, type_validator, properties_validator])

    expect(registry.validators_for({ "type" => "number", "maximum" => 10 })).to eq(
      [range_validator, type_validator],
    )
  end

  it "rejects strategies that do not declare handled keywords" do
    incomplete_validator = Class.new(Ucfg::JSONSchema::Validator)

    expect { described_class.new([incomplete_validator]) }
      .to raise_error(ArgumentError, "validators must define .validate and handle at least one keyword")
  end

  it "rejects strategies that do not implement validation" do
    incomplete_validator = Class.new(Ucfg::JSONSchema::Validator) do
      handles "type"
    end

    expect { described_class.new([incomplete_validator]) }
      .to raise_error(ArgumentError, "validators must define .validate and handle at least one keyword")
  end

  it "registers every built-in validator through the common protocol" do
    expect(Ucfg::JSONSchema::VALIDATORS).to all(be < Ucfg::JSONSchema::Validator)
    expect(Ucfg::JSONSchema::VALIDATORS.flat_map(&:handles)).to include(
      "allOf",
      "anyOf",
      "maximum",
      "minLength",
      "oneOf",
      "properties",
      "type",
    )
  end
end
