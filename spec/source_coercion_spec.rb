# frozen_string_literal: true

RSpec.describe Ucfg::SourceCoercion do
  it "accepts objects with string coercion" do
    source = Object.new
    source.define_singleton_method(:to_str) { "name: ucfg\n" }

    expect(described_class.to_string(source, label: "YAML")).to eq("name: ucfg\n")
  end

  it "raises a domain error with the supplied source label" do
    expect { described_class.to_string(123, label: "Template") }
      .to raise_error(Ucfg::Error, "Template source must be a string")
  end
end
