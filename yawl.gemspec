# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'yawl/version'

Gem::Specification.new do |spec|
  spec.name          = "yawl"
  spec.version       = Yawl::VERSION
  spec.authors       = ["Ricardo Chimal, Jr."]
  spec.email         = ["kiwi@null.cx"]
  spec.description   = %q{Yet Another Workflow Library for Ruby}
  spec.summary       = %q{Yet Another Workflow Library for Ruby}
  spec.homepage      = "https://github.com/ricardochimal/yawl"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "sequel"
  spec.add_dependency "scrolls"
  spec.add_dependency "queue_classic", "2.2.3"
  spec.add_dependency "queue_classic-later", ">= 0.3.0"

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
end
