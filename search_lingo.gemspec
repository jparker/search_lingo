# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'search_lingo/version'

Gem::Specification.new do |spec|
  spec.name          = "search_lingo"
  spec.version       = SearchLingo::VERSION
  spec.authors       = ["John Parker"]
  spec.email         = ["jparker@urgetopunt.com"]

  spec.summary       = %q{Framework for defining and parsing search queries.}
  spec.description   = %q{SearchLingo is a simple framework for defining simple query languages and translating them into application-specific queries.}
  spec.homepage      = "https://github.com/jparker/search_lingo"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.rdoc_options += ['-x', 'examples/', '-x', 'test/']

  spec.required_ruby_version = '>= 2.1'

  spec.add_development_dependency "bundler", "~> 1.9"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency 'minitest'
  spec.add_development_dependency 'minitest-focus'
  spec.add_development_dependency 'mocha'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'sequel', '~> 5.0'
  spec.add_development_dependency 'sqlite3'
end
