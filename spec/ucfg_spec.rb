# frozen_string_literal: true

require "tmpdir"

RSpec.describe Ucfg do
  it "has a version number" do
    expect(Ucfg::VERSION).not_to be nil
  end

  describe ".load_files" do
    it "merges two files from left to right" do
      allow(described_class).to receive(:load_file).with("base.yml", erb: false, env: false, env_parsers: {}).and_return({ "a" => 1 })
      allow(described_class).to receive(:load_file).with("override.yml", erb: false, env: false, env_parsers: {}).and_return({ "b" => 2 })

      merger = double("Ucfg::ConfigMerger")
      stub_const("Ucfg::ConfigMerger", merger)

      expect(merger).to receive(:merge).with({}, { "a" => 1 }).ordered.and_return({ "a" => 1 })
      expect(merger).to receive(:merge).with({ "a" => 1 }, { "b" => 2 }).ordered.and_return({ "a" => 1, "b" => 2 })

      result = described_class.load_files("base.yml", "override.yml")

      expect(result).to eq({ "a" => 1, "b" => 2 })
    end

    it "applies three-file precedence with later files overriding earlier ones" do
      allow(described_class).to receive(:load_file).with("one.yml", erb: false, env: false, env_parsers: {}).and_return({ "timeout" => 10 })
      allow(described_class).to receive(:load_file).with("two.yml", erb: false, env: false, env_parsers: {}).and_return({ "timeout" => 20 })
      allow(described_class).to receive(:load_file).with("three.yml", erb: false, env: false, env_parsers: {}).and_return({ "timeout" => 30 })

      merger = double("Ucfg::ConfigMerger")
      stub_const("Ucfg::ConfigMerger", merger)

      expect(merger).to receive(:merge).with({}, { "timeout" => 10 }).ordered.and_return({ "timeout" => 10 })
      expect(merger).to receive(:merge).with({ "timeout" => 10 }, { "timeout" => 20 }).ordered.and_return({ "timeout" => 20 })
      expect(merger).to receive(:merge).with({ "timeout" => 20 }, { "timeout" => 30 }).ordered.and_return({ "timeout" => 30 })

      result = described_class.load_files("one.yml", "two.yml", "three.yml")

      expect(result).to eq({ "timeout" => 30 })
    end

    it "delegates nested hash cases to ConfigMerger and returns its result" do
      allow(described_class).to receive(:load_file).with("base.yml", erb: false, env: false, env_parsers: {}).and_return({
                                                                                                                           "service" => { "host" => "localhost", "port" => 8080 },
                                                                                                                         })
      allow(described_class).to receive(:load_file).with("override.yml", erb: false, env: false, env_parsers: {}).and_return({
                                                                                                                               "service" => { "port" => 9090 },
                                                                                                                             })

      merger = double("Ucfg::ConfigMerger")
      stub_const("Ucfg::ConfigMerger", merger)

      merged_after_first = { "service" => { "host" => "localhost", "port" => 8080 } }
      final_merged = { "service" => { "host" => "localhost", "port" => 9090 } }

      expect(merger).to receive(:merge).with({}, {
                                               "service" => { "host" => "localhost", "port" => 8080 },
                                             }).ordered.and_return(merged_after_first)
      expect(merger).to receive(:merge).with(merged_after_first, {
                                               "service" => { "port" => 9090 },
                                             }).ordered.and_return(final_merged)

      result = described_class.load_files("base.yml", "override.yml")

      expect(result).to eq(final_merged)
    end

    it "delegates array cases to ConfigMerger and returns its result" do
      allow(described_class).to receive(:load_file).with("base.yml", erb: false, env: false, env_parsers: {}).and_return({ "hosts" => %w[a b] })
      allow(described_class).to receive(:load_file).with("override.yml", erb: false, env: false, env_parsers: {}).and_return({ "hosts" => ["c"] })

      merger = double("Ucfg::ConfigMerger")
      stub_const("Ucfg::ConfigMerger", merger)

      expect(merger).to receive(:merge).with({}, { "hosts" => %w[a b] }).ordered.and_return({ "hosts" => %w[a b] })
      expect(merger).to receive(:merge).with({ "hosts" => %w[a b] }, { "hosts" => ["c"] }).ordered.and_return({ "hosts" => ["c"] })

      result = described_class.load_files("base.yml", "override.yml")

      expect(result).to eq({ "hosts" => ["c"] })
    end

    it "applies ERB rendering to every file when erb is enabled" do
      Dir.mktmpdir do |dir|
        first = File.join(dir, "first.yml")
        second = File.join(dir, "second.yml")

        File.write(first, "host: <%= ENV['CFG_HOST'] %>\n")
        File.write(second, "port: <%= ENV['CFG_PORT'] %>\n")

        with_env("CFG_HOST", "example.test") do
          with_env("CFG_PORT", "443") do
            merger = Module.new do
              def self.merge(base, override)
                base.merge(override)
              end
            end
            stub_const("Ucfg::ConfigMerger", merger)

            result = described_class.load_files(first, second, erb: true)

            expect(result).to eq({ "host" => "example.test", "port" => 443 })
          end
        end
      end
    end

    it "raises Ucfg::Error when no paths are provided" do
      expect { described_class.load_files }
        .to raise_error(Ucfg::Error, /at least one file path must be provided/i)
    end
  end

  def with_env(key, value)
    original = ENV.fetch(key, nil)

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
