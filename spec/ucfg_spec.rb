# frozen_string_literal: true

require "tmpdir"

RSpec.describe Ucfg do
  describe ".load_files" do
    it "applies ERB rendering to every file when erb is enabled" do
      Dir.mktmpdir do |dir|
        first = File.join(dir, "first.yml")
        second = File.join(dir, "second.yml")

        File.write(first, "host: <%= ENV['CFG_HOST'] %>\n")
        File.write(second, "port: <%= ENV['CFG_PORT'] %>\n")

        with_env("CFG_HOST", "example.test") do
          with_env("CFG_PORT", "443") do
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
