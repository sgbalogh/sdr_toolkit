# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'sdr_toolkit/version'
require 'sdr_toolkit/sdr_event'
require 'sdr_toolkit/fda_rest'
require 'sdr_toolkit/postgis_event'
require 'sdr_toolkit/utils'
require 'sdr_toolkit/documents/ogm_record'
require 'sdr_toolkit/documents/fda_record'
require 'sdr_toolkit/documents/bbox_coordinates'
require 'figs'
require 'mongoid'
Figs.load()
Mongoid.load!("config/mongoid.yml")

Gem::Specification.new do |spec|
  spec.name          = "sdr_toolkit"
  spec.version       = SdrToolkit::VERSION
  spec.authors       = ["Stephen Balogh"]
  spec.email         = ["sgb334@nyu.edu"]

  spec.summary       = 'Toolkit for managing the NYU Spatial Data Repository'
  spec.description   = 'A collection of utilities for interacting with various repository APIs related to the NYU Spatial Data Repository'
  spec.homepage      = "https://geo.nyu.edu"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency 'figs'
  spec.add_dependency 'mongoid'
  spec.add_dependency 'pg'

  spec.add_development_dependency "bundler", "~> 1.12"
  spec.add_development_dependency "rake", "~> 10.0"
end
