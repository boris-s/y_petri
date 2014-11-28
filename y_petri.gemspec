# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'y_petri/version'

Gem::Specification.new do |spec|
  spec.name          = "y_petri"
  spec.version       = YPetri::VERSION
  spec.authors       = ["boris"]
  spec.email         = ["\"boris@iis.sinica.edu.tw\""]
  spec.summary       = %q{Systems modelling and simulation gem, and a domain model of a specific type of universal Petri net (YPetri net), which can be used to model any kind of dynamical system whatsoever.}
  spec.description   = %q{YPetri is a gem for modelling of dynamical systems. It caters solely to the two main concerns of modelling, model specification and simulation, and it excels in the first one. Dynamical systems are described under a Petri net paradigm. YPetri implements a universal Petri net abstraction that integrates discrete/continous, deterministic/stochastic, timed/timeless and stoichiometric/nonstoichiometric dichotomies of the extended Petri nets, and allows efficient specification of any kind of dynamical system. Like Petri nets themselves, YPetri was inspired by problems from the domain of chemistry (biochemical pathway modelling), but it is not specific it. Other gems, YChem and YCell are planned to cater to the concerns specific to chemistry and cell biochemistry. As a part of this effort, an extended version of YPetri is under development. Its name is YNelson, its usage is practically identical to YPetri, but it covers more concerns than just Petri net specification and simulation. Namely, YNelson allows relations among Petri net nodes and parameters to be captured under a zz structure paradigm (which was developed by Ted Nelson) and it also provides higher level of abstraction in Petri net specification by providing commands that create more than one Petri net node per command.}
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
  
  spec.required_ruby_version = '>= 2.0'
end
