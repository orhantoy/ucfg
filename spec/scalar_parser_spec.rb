# frozen_string_literal: true

RSpec.describe Ucfg::ScalarParser do
  it "parses supported scalar values" do
    expect(described_class.parse("true")).to eq(true)
    expect(described_class.parse("false")).to eq(false)
    expect(described_class.parse("null")).to be_nil
    expect(described_class.parse("0")).to eq(0)
    expect(described_class.parse("-12")).to eq(-12)
    expect(described_class.parse("1.5")).to eq(1.5)
    expect(described_class.parse("1e6")).to eq(1_000_000.0)
    expect(described_class.parse("-1.5e-2")).to eq(-0.015)
  end

  it "preserves unsupported and non-canonical values as strings" do
    %w[TRUE 01 +1 .5 1.].each do |value|
      expect(described_class.parse(value)).to eq(value)
    end
  end
end
