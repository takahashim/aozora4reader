# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'aozora4reader/version'

Gem::Specification.new do |spec|
  spec.name          = "aozora4reader"
  spec.version       = Aozora4reader::VERSION
  spec.authors       = ["takahashim"]
  spec.email         = ["maki@rubycolor.org"]
  spec.description   = %q{Aozora Bunko converter for Sony Reader}
  spec.summary       = %q{Aozora Bunko converter for Sony Reader}
  spec.homepage      = "http://github.com/takahashim/aozora4reader"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
end
