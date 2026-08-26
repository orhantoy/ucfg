# frozen_string_literal: true

RSpec.describe Ucfg::ValidationError do
  it "exposes structured error attributes and a hash representation" do
    error = described_class.new(
      message: "Property `service.port` must be of type `integer`",
      path: ["service", "port"],
      keyword: "type",
      type: :validation,
    )

    expect(error.message).to eq("Property `service.port` must be of type `integer`")
    expect(error.path).to eq(["service", "port"])
    expect(error.keyword).to eq("type")
    expect(error.type).to eq(:validation)
    expect(error.to_h).to eq(
      :message => "Property `service.port` must be of type `integer`",
      :path => ["service", "port"],
      :keyword => "type",
      :type => :validation,
    )
    expect(error.to_s).to eq("Property `service.port` must be of type `integer`")
  end

  it "compares equal to its message for compatibility" do
    error = described_class.new(message: "message")

    expect(error).to eq("message")
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
      :message => "message",
      :path => ["name"],
      :keyword => "type",
      :type => :validation,
    )
  end
end
