# frozen_string_literal: true

RSpec.describe "result value objects" do
  it "exposes immutable validation errors" do
    source_errors = ["invalid"]
    result = Ucfg::ValidationResult.new(validation_errors: source_errors)
    source_errors << "added later"

    expect(result.errors).to eq(["invalid"])
    expect(result).to be_frozen
    expect(result.errors).to be_frozen
    expect(result.error_details).to be_frozen
    expect(result.error_details.first).to be_frozen
    expect { result.errors << "another" }.to raise_error(FrozenError)
    expect { result.error_details.clear }.to raise_error(FrozenError)
  end

  it "keeps load result state immutable without freezing configuration" do
    config = { "name" => "ucfg" }
    result = Ucfg::LoadResult.new(config: config, errors: ["invalid"])

    expect(result).to be_frozen
    expect(result.errors).to be_frozen
    expect(result.error_details).to be_frozen

    result.config["name"] = "updated"
    expect(result.config).to eq("name" => "updated")
  end
end
