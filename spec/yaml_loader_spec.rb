# frozen_string_literal: true

RSpec.describe Ucfg::YAMLLoader do
  describe ".load" do
    it "supports a top-level array root" do
      yaml = <<~YAML
        - app
        - 42
        - true
      YAML

      expect(described_class.load(yaml)).to eq(["app", 42, true])
    end

    it "supports top-level scalar roots" do
      expect(described_class.load("hello\n")).to eq("hello")
      expect(described_class.load("42\n")).to eq(42)
      expect(described_class.load("false\n")).to eq(false)
      expect(described_class.load("null\n")).to eq(nil)
    end

    it "parses supported scalars without YAML implicit boolean surprises" do
      yaml = <<~YAML
        mode: production
        on_value: on
        off_value: off
        yes_value: yes
        no_value: no
        enabled: true
        disabled: false
        missing: null
        count: 42
        price: 12.5
        ratio: 1e6
        message: "hello world"
      YAML

      expect(described_class.load(yaml)).to eq(
        {
          "mode" => "production",
          "on_value" => "on",
          "off_value" => "off",
          "yes_value" => "yes",
          "no_value" => "no",
          "enabled" => true,
          "disabled" => false,
          "missing" => nil,
          "count" => 42,
          "price" => 12.5,
          "ratio" => 1_000_000.0,
          "message" => "hello world",
        },
      )
    end

    it "treats non-canonical numeric-looking values as strings" do
      yaml = <<~YAML
        leading_zero: 01
        explicit_plus: +1
        leading_decimal: .5
        canonical_negative_float: -0.5
        exponent_float: 1.0e6
      YAML

      expect(described_class.load(yaml)).to eq(
        {
          "leading_zero" => "01",
          "explicit_plus" => "+1",
          "leading_decimal" => ".5",
          "canonical_negative_float" => -0.5,
          "exponent_float" => 1_000_000.0,
        },
      )
    end

    it "parses nested objects and arrays" do
      yaml = <<~YAML
        server:
          host: localhost
          ports:
            - 443
            - 8443
        environments:
          - name: production
            enabled: true
          - name: staging
            enabled: false
      YAML

      expect(described_class.load(yaml)).to eq(
        {
          "server" => {
            "host" => "localhost",
            "ports" => [443, 8443],
          },
          "environments" => [
            { "name" => "production", "enabled" => true },
            { "name" => "staging", "enabled" => false },
          ],
        },
      )
    end

    it "treats omitted values as null" do
      yaml = <<~YAML
        server:
          host: localhost
          port:
        feature.enabled:
      YAML

      expect(described_class.load(yaml)).to eq(
        {
          "server" => {
            "host" => "localhost",
            "port" => nil,
          },
          "feature" => {
            "enabled" => nil,
          },
        },
      )
    end

    it "supports dot notation alongside indentation-based nesting" do
      yaml = <<~YAML
        server:
          host: localhost
        database.port: 5432
        database.enabled: true
      YAML

      expect(described_class.load(yaml)).to eq(
        {
          "server" => { "host" => "localhost" },
          "database" => {
            "port" => 5432,
            "enabled" => true,
          },
        },
      )
    end

    it "raises for duplicate keys" do
      yaml = <<~YAML
        name: app
        name: other
      YAML

      expect { described_class.load(yaml) }.to raise_error(Ucfg::Error, /duplicate key/i)
    end

    it "raises when a path is both a scalar and an object" do
      yaml = <<~YAML
        server: localhost
        server.port: 5432
      YAML

      expect { described_class.load(yaml) }.to raise_error(Ucfg::Error, /scalar.*object|object.*scalar/i)
    end

    it "raises for unsupported flow style collections" do
      yaml = <<~YAML
        items: [one, two]
      YAML

      expect { described_class.load(yaml) }.to raise_error(Ucfg::Error, /flow style/i)
    end

    it "raises for unsupported aliases" do
      yaml = <<~YAML
        defaults: &defaults
          host: localhost
        server: *defaults
      YAML

      expect { described_class.load(yaml) }.to raise_error(Ucfg::Error, /alias|anchor/i)
    end

    it "raises for unsupported merge keys" do
      yaml = <<~YAML
        server:
          <<:
            host: localhost
      YAML

      expect { described_class.load(yaml) }.to raise_error(Ucfg::Error, /merge key/i)
    end

    it "raises for unsupported explicit tags" do
      yaml = <<~YAML
        value: !custom tagged
      YAML

      expect { described_class.load(yaml) }.to raise_error(Ucfg::Error, /explicit tag/i)
    end

    it "raises for unsupported block scalars" do
      yaml = <<~YAML
        message: |
          hello
      YAML

      expect { described_class.load(yaml) }.to raise_error(Ucfg::Error, /block scalar/i)
    end

    it "raises for tabs in indentation" do
      yaml = "server:\n\tport: 5432\n"

      expect { described_class.load(yaml) }.to raise_error(Ucfg::Error, /invalid yaml syntax/i)
    end

    it "raises for malformed indentation" do
      yaml = <<~YAML
        server:
          host: localhost
           port: 5432
      YAML

      expect { described_class.load(yaml) }.to raise_error(Ucfg::Error, /invalid yaml syntax/i)
    end

    it "raises for an empty yaml document" do
      expect { described_class.load("") }.to raise_error(Ucfg::Error, /document is empty/i)
      expect { described_class.load("   \n") }.to raise_error(Ucfg::Error, /document is empty/i)
    end

    it "raises for a comment-only yaml document" do
      yaml = <<~YAML
        # comment
        # another comment
      YAML

      expect { described_class.load(yaml) }.to raise_error(Ucfg::Error, /document is empty/i)
    end

    it "raises for multi-document input" do
      yaml = <<~YAML
        first: true
        ---
        second: false
      YAML

      expect { described_class.load(yaml) }.to raise_error(Ucfg::Error, /multi-document/i)
    end
  end
end
