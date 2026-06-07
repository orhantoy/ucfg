lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "ucfg/version"

Gem::Specification.new do |spec|
  spec.name          = "ucfg"
  spec.version       = Ucfg::VERSION
  spec.authors       = ["Orhan Toy"]
  spec.email         = ["toyorhan@gmail.com"]

  spec.summary       = %q{Ruby Universal Configuration}
  spec.description   = %q{Configuration file validation with JSON Schema}
  spec.homepage      = "https://github.com/orhantoy/ucfg"
  spec.required_ruby_version = ">= 3.1"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/orhantoy/ucfg"
  spec.metadata["changelog_uri"] = "https://github.com/orhantoy/ucfg/releases"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files         = Dir.chdir(__dir__) do
    Dir.glob(%w[lib/**/* LICENSE* README* CHANGELOG*]).select { |file| File.file?(file) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 2.6"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.13"
end
