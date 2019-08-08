# frozen_string_literal: true

RSpec.describe Ucfg do
  it "has a version number" do
    expect(Ucfg::VERSION).not_to be nil
  end

  it "does something useful" do
    raw_config = <<-CONFIG
      hello: world
      namespace.setting: 2
      namespace.other_setting: 5
      namespace.dynamic_setting: ${SUB_THIS}
    CONFIG

    options = {
      "SUB_THIS" => "with this"
    }

    config = Ucfg.parse(raw_config, options)
    expect(config["hello"]).to eq("world")
    expect(config.dig("namespace", "setting")).to eq(2)
    expect(config.dig("namespace", "dynamic_setting")).to eq("with this")
  end

  it "does something more useful" do
    raw_config = <<-CONFIG
      -
        hello: world
        key: ${SUB_THIS}
    CONFIG

    options = {
      "SUB_THIS" => "with this"
    }

    config = Ucfg.parse(raw_config, options)
    expect(config.dig(0, "hello")).to eq("world")
    expect(config.dig(0, "key")).to eq("with this")
  end

  it "handles nil" do
    raw_config = <<-CONFIG
      null
    CONFIG

    options = {
      "SUB_THIS" => "with this"
    }

    config = Ucfg.parse(raw_config, options)
    expect(config).to eq(nil)
  end

  it "fails" do
    raw_config = <<-CONFIG
      key: ${SUB_THIS}
    CONFIG

    expect { Ucfg.parse(raw_config, {}) }.to raise_error(Ucfg::InvalidSubstitution)
  end
end
