# frozen_string_literal: true

RSpec.describe Ucfg::TemplateRenderer do
  describe ".render" do
    it "returns the original source when ERB rendering is disabled" do
      source = "api_key: <%= ENV['API_KEY'] %>"

      expect(described_class.render(source, erb: false)).to eq(source)
    end

    it "expands ENV values when environment rendering is enabled" do
      with_env("API_KEY", "secret-token") do
        rendered = described_class.render("api_key: ${API_KEY}", env: true)

        expect(rendered).to eq("api_key: secret-token")
      end
    end

    it "supports default values when environment rendering is enabled" do
      with_env("MISSING", nil) do
        rendered = described_class.render("value: ${MISSING:default}", env: true)

        expect(rendered).to eq("value: default")
      end
    end

    it "does not allow ERB and environment rendering at the same time" do
      expect { described_class.render("value: ${VALUE}", erb: true, env: true) }
        .to raise_error(Ucfg::Error, /cannot be enabled together/i)
    end

    it "interpolates ENV values when ERB rendering is enabled" do
      with_env("API_KEY", "secret-token") do
        rendered = described_class.render("api_key: <%= ENV['API_KEY'] %>", erb: true)

        expect(rendered).to eq("api_key: secret-token")
      end
    end

    it "supports default-value logic in ERB expressions" do
      with_env("MISSING", nil) do
        rendered = described_class.render("value: <%= ENV['MISSING'] || 'default' %>", erb: true)

        expect(rendered).to eq("value: default")
      end
    end

    it "raises Ucfg::Error for invalid ERB syntax" do
      source = "value: <%= ENV['API_KEY' %>"

      expect { described_class.render(source, erb: true) }
        .to raise_error(Ucfg::Error, /invalid erb syntax/i)
    end

    it "raises Ucfg::Error for non-string input" do
      expect { described_class.render(123, erb: false) }
        .to raise_error(Ucfg::Error, /template source must be a string/i)
      expect { described_class.render(123, erb: true) }
        .to raise_error(Ucfg::Error, /template source must be a string/i)
    end
  end

  def with_env(key, value)
    original = ENV[key]

    if value.nil?
      ENV.delete(key)
    else
      ENV[key] = value
    end

    yield
  ensure
    if original.nil?
      ENV.delete(key)
    else
      ENV[key] = original
    end
  end
end
