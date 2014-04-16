# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'y_petri/version'

Gem::Specification.new do |spec|
  spec.name          = "y_petri"
  spec.version       = YPetri::VERSION
  spec.authors       = ["boris"]
  spec.email         = ["\"boris@iis.sinica.edu.tw\""]
  spec.summary       = %q{Systems modelling and simulation gem, and a domain model of a special kind of Petri nets (YPetri nets) that can be used to model and simulate any kind of dynamic systems.}
  spec.description   = %q{YPetri is a gem for modelling and simulation of dynamic systems. Wiring diagram of a dynamic system to be modelled is expressed as YPetri net, a specific kind of Petri net that unifies discrete/continous, deterministic/stochastic, timed/timeless and stoichiometric/nonstoichiometric dichotomies, thus enabling modelling and simulation of dynamic systems of any kind whatsoever. Like Petri nets themselves, YPetri was inspired by problems from the domain of chemistry, but its use is not limited to it.}
  spec.homepage      = ""
  spec.license       = "GPLv3"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake"
  spec.add_dependency "y_support"
  spec.add_dependency "gnuplot"
  spec.add_dependency "ruby-graphviz"
  spec.add_dependency "distribution"
end
