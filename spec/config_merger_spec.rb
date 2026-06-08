# frozen_string_literal: true

RSpec.describe Ucfg::ConfigMerger do
  describe ".merge" do
    it "prefers override values for matching scalar keys" do
      merged = described_class.merge({ "a" => 1 }, { "a" => 2 })

      expect(merged).to eq({ "a" => 2 })
    end

    it "deep merges nested hashes" do
      merged = described_class.merge(
        { "a" => { "b" => 1 } },
        { "a" => { "c" => 2 } }
      )

      expect(merged).to eq({ "a" => { "b" => 1, "c" => 2 } })
    end

    it "applies nil values from the override" do
      merged = described_class.merge(
        { "a" => { "b" => 1, "c" => 2 } },
        { "a" => { "b" => nil } }
      )

      expect(merged).to eq({ "a" => { "b" => nil, "c" => 2 } })
    end

    it "replaces arrays instead of concatenating them" do
      merged = described_class.merge(
        { "a" => [1, 2] },
        { "a" => [3] }
      )

      expect(merged).to eq({ "a" => [3] })
    end

    it "treats nil input as an empty hash" do
      expect(described_class.merge(nil, nil)).to eq({})
      expect(described_class.merge(nil, { "a" => 1 })).to eq({ "a" => 1 })
      expect(described_class.merge({ "a" => 1 }, nil)).to eq({ "a" => 1 })
    end

    it "raises Ucfg::Error when base is non-nil and not a hash" do
      expect { described_class.merge([], {}) }
        .to raise_error(Ucfg::Error, /base config must be a hash or nil/i)
    end

    it "raises Ucfg::Error when override is non-nil and not a hash" do
      expect { described_class.merge({}, []) }
        .to raise_error(Ucfg::Error, /override config must be a hash or nil/i)
    end

    it "does not mutate either input hash" do
      base = {
        "nested" => { "value" => 1 },
        "array" => [1, 2]
      }
      override = {
        "nested" => { "other" => 2 },
        "array" => [3]
      }

      base_before = Marshal.load(Marshal.dump(base))
      override_before = Marshal.load(Marshal.dump(override))

      described_class.merge(base, override)

      expect(base).to eq(base_before)
      expect(override).to eq(override_before)
    end

    it "preserves string and symbol keys as-is" do
      merged = described_class.merge(
        { "a" => 1, b: 2 },
        { "a" => 3, b: 4, c: 5, "d" => 6 }
      )

      expect(merged).to eq({ "a" => 3, b: 4, c: 5, "d" => 6 })
      expect(merged.keys).to contain_exactly("a", :b, :c, "d")
    end

    it "returns an independent merged hash" do
      base = { "a" => { "b" => 1 }, "arr" => [1, 2], "name" => "base-name" }
      override = { "a" => { "c" => 2 }, "arr" => [3], "title" => "override-title" }

      merged = described_class.merge(base, override)
      merged["a"]["b"] = 99
      merged["arr"] << 4
      merged["name"] << "-changed"
      merged["title"] << "-changed"

      expect(base).to eq({ "a" => { "b" => 1 }, "arr" => [1, 2], "name" => "base-name" })
      expect(override).to eq({ "a" => { "c" => 2 }, "arr" => [3], "title" => "override-title" })
    end
  end
end
