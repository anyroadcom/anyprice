# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'pricing_definition/version'

Gem::Specification.new do |spec|
  spec.name          = "pricing_definition"
  spec.version       = PricingDefinition::VERSION
  spec.authors       = ["Ioannis Tziligkakis"]
  spec.email         = ["gtsiligkakis@gmail.com"]
  spec.summary       = %q{Adds pricing definition functionality for ActiveRecord model}
  spec.description   = %q{Provides seasonal pricing, fixed or varying pricing based on the number of participants}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.test_files    = spec.files.grep(%r{^(spec)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "activerecord", "~> 4.1"
  spec.add_dependency "activesupport", "~> 4.1"
  spec.add_dependency "rschema", "~> 0.1"

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "pry", "~> 0.10"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "sqlite3", "~> 1.3"
  spec.add_development_dependency "timecop", "~> 0.7"
end
