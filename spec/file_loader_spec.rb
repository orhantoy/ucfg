# frozen_string_literal: true

require "pathname"
require "tmpdir"

RSpec.describe Ucfg::FileLoader do
  describe ".read" do
    it "reads content from a readable file" do
      Dir.mktmpdir do |dir|
        path = File.join(dir, "config.yml")
        File.write(path, "name: app\n")

        expect(described_class.read(path)).to eq("name: app\n")
      end
    end

    it "returns an empty string for an empty file" do
      Dir.mktmpdir do |dir|
        path = File.join(dir, "empty.yml")
        File.write(path, "")

        expect(described_class.read(path)).to eq("")
      end
    end

    it "raises Ucfg::Error when the file is missing" do
      Dir.mktmpdir do |dir|
        path = File.join(dir, "missing.yml")

        expect { described_class.read(path) }
          .to raise_error(Ucfg::Error, /Failed to read file `#{Regexp.escape(path)}`: No such file or directory/i)
      end
    end

    it "raises Ucfg::Error when the file is unreadable" do
      Dir.mktmpdir do |dir|
        path = File.join(dir, "private.yml")
        File.write(path, "secret: true\n")
        File.chmod(0o000, path)

        if File.readable?(path)
          skip("unable to make file unreadable in this environment")
        end

        expect { described_class.read(path) }
          .to raise_error(Ucfg::Error, /Failed to read file `#{Regexp.escape(path)}`: Permission denied/i)
      ensure
        File.chmod(0o644, path) if File.exist?(path)
      end
    end

    it "accepts path-like objects" do
      Dir.mktmpdir do |dir|
        path = File.join(dir, "config.yml")
        File.write(path, "enabled: true\n")

        expect(described_class.read(Pathname.new(path))).to eq("enabled: true\n")
      end
    end
  end
end
