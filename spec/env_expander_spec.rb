# frozen_string_literal: true

RSpec.describe Ucfg::EnvExpander do
  describe ".expand" do
    it "expands strings from ENV" do
      with_env("HOST", "localhost") do
        expect(described_class.expand("${HOST}")).to eq("localhost")
      end
    end

    it "expands embedded values as strings" do
      with_env("ENVIRONMENT", "prod") do
        expect(described_class.expand("api-${ENVIRONMENT}")).to eq("api-prod")
      end
    end

    it "uses defaults for missing and empty environment variables" do
      with_env("MISSING", nil) do
        with_env("EMPTY", "") do
          expect(described_class.expand("${MISSING:default}")).to eq("default")
          expect(described_class.expand("${EMPTY:default}")).to eq("default")
        end
      end
    end

    it "expands nested defaults before applying whole-value typing" do
      with_env("A", nil) do
        with_env("B", nil) do
          expect(described_class.expand("${A:${B:null}}")).to be_nil
        end

        with_env("HOSTS", "h1,h2") do
          expect(described_class.expand("${A:${HOSTS}}")).to eq(["h1", "h2"])
        end
      end
    end

    it "preserves dollar-close-brace sequences literally" do
      expect(described_class.expand("prompt: $}")).to eq("prompt: $}")
      expect(described_class.expand("prompt: $} ${MISSING:value}")).to eq("prompt: $} value")
    end

    it "parses whole-value environment expansions into scalar values" do
      expect(described_class.expand("${ENABLED:true}")).to eq(true)
      expect(described_class.expand("${REPLICAS:3}")).to eq(3)
      expect(described_class.expand("${RATIO:1.5}")).to eq(1.5)
      expect(described_class.expand("${MISSING:null}")).to be_nil
    end

    it "parses comma-separated whole-value expansions into arrays" do
      with_env("HOSTS", "host1:9200,host2:9200") do
        expect(described_class.expand("${HOSTS}")).to eq(["host1:9200", "host2:9200"])
      end
    end

    it "expands recursively through hashes and arrays" do
      config = {
        "service" => {
          "enabled" => "${ENABLED:true}",
          "hosts" => ["${HOST:localhost}"],
        },
      }

      expect(described_class.expand(config)).to eq(
        "service" => {
          "enabled" => true,
          "hosts" => ["localhost"],
        },
      )
    end

    it "raises for missing variables without defaults" do
      with_env("MISSING", nil) do
        expect { described_class.expand("${MISSING}") }
          .to raise_error(Ucfg::Error, /environment variable `MISSING` is not set/i)
      end
    end

    it "raises for malformed expansions" do
      expect { described_class.expand("${MISSING") }
        .to raise_error(Ucfg::Error, /missing `}`/i)
      expect { described_class.expand("${}") }
        .to raise_error(Ucfg::Error, /empty environment expansion/i)
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