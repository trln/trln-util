# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'trln/util/meta'

Gem::Specification.new do |spec|
  spec.name          = "trln-util"
  spec.version       = TRLN::Util::VERSION
  spec.authors       = ["Adam Constabaris"]
  spec.email         = ["adam_constabaris@ncsu.edu"]

  spec.summary       = %q{Utilities for working with documents that enhance TRLN shared records}
  spec.description   = %q{Catalog records may require merging data from multiple data sources, including purchased record sets or other library data}
  spec.homepage      = "https://www.trln.org"
  spec.license       = "GPL-3.0"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "http://mygemserver.com"
  else
    raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = `git ls-files -- exe/*`.split("\n").map { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency 'nokogiri', '~> 1.7'
  spec.add_runtime_dependency 'thor', '~> 0.19'
  spec.add_runtime_dependency 'library_stdnums', ['~> 1.4', '>= 1.4.1']
  spec.add_runtime_dependency 'rsolr' , [ '~> 1.1', ">= 1.1.2"]

  spec.add_development_dependency "bundler", "~> 1.12"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end
