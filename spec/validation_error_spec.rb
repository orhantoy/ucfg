# frozen_string_literal: true

RSpec.describe Ucfg::ValidationError do
  it "exposes structured error attributes and a hash representation" do
    error = described_class.new(
      message: "Property `service.port` must be of type `integer`",
      path: %w[service port],
      keyword: "type",
      type: :validation,
    )

    expect(error.message).to eq("Property `service.port` must be of type `integer`")
    expect(error.path).to eq(%w[service port])
    expect(error.keyword).to eq("type")
    expect(error.type).to eq(:validation)
    expect(error.to_h).to eq(
      message: "Property `service.port` must be of type `integer`",
      path: %w[service port],
      keyword: "type",
      type: :validation,
    )
    expect(error.to_s).to eq("Property `service.port` must be of type `integer`")
  end

  it "uses symmetric value equality and hashing" do
    error = described_class.new(message: "message", path: ["name"], keyword: "type")
    matching_error = described_class.new(message: "message", path: ["name"], keyword: "type")

    expect(error).to eq(matching_error)
    expect(error).to eql(matching_error)
    expect(error.hash).to eq(matching_error.hash)
    expect({ error => :found }.fetch(matching_error)).to eq(:found)
    expect(error).not_to eq("message")
    expect("message").not_to eq(error)
  end

  it "copies and freezes its value state" do
    message = +"message"
    segment = +"name"
    keyword = +"type"
    error = described_class.new(message: message, path: [segment], keyword: keyword)

    message << " changed"
    segment << " changed"
    keyword << " changed"

    expect(error.to_h).to eq(
      message: "message",
      path: ["name"],
      keyword: "type",
      type: :validation,
    )
    expect(error).to be_frozen
    expect(error.message).to be_frozen
    expect(error.path).to be_frozen
    expect(error.path.first).to be_frozen
    expect(error.keyword).to be_frozen
  end

  it "can be normalized from string-keyed hashes by result objects" do
    result = Ucfg::ValidationResult.new(
      error_details: [
        {
          "message" => "message",
          "path" => ["name"],
          "keyword" => "type",
          "type" => :validation,
        },
      ],
    )

    expect(result.errors).to eq(["message"])
    expect(result.error_details.first.to_h).to eq(
      message: "message",
      path: ["name"],
      keyword: "type",
      type: :validation,
    )
    expect(result).to be_frozen
    expect(result.errors).to be_frozen
    expect(result.error_details).to be_frozen
  end
end
