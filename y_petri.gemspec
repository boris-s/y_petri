# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'y_petri/version'

Gem::Specification.new do |spec|
  spec.name          = "y_petri"
  spec.version       = YPetri::VERSION
  spec.authors       = ["boris"]
  spec.email         = ["\"boris@iis.sinica.edu.tw\""]
  spec.summary       = %q{Systems modelling and simulation gem. Biologically inspired, but concerns specific to biology and chemistry have been purposely separated away from it, so it is a general-purpose model specification and simulation DSL. Dynamical systems are specified by a specific universal type of a hybrid Petri net which YPetri implements and which allows description of any kind of dynamical system whatsoever.}
  spec.description   = %q{YPetri is a gem for modelling of dynamical systems. It is biologically inspired, but concerns of biology and chemistry have been purposely separated away from it. YPetri caters solely to the two main concerns of modelling, model specification and simulation, and it excels in the first one. Dynamical systems are described under a Petri net paradigm. YPetri implements a universal Petri net abstraction that integrates discrete/continous, deterministic/stochastic, timed/timeless and stoichiometric/nonstoichiometric dichotomies of the extended Petri nets, and allows efficient specification of any kind of dynamical system. Like Petri nets themselves, YPetri was inspired by problems from the domain of chemistry (biochemical pathway modelling), but is not specific to it. Other gems, YChem and YCell are planned to cater to the concerns specific to chemistry and cell biochemistry. These future extensions of YPetri are not developed yet. A lower-level extension of YPetri is currently under development under the name YNelson. Its usage is practically identical to YPetri, so any YPetri user can now consider using YNelson instead. YNelson covers additional concerns: it allows relations among nodes and parameters to be specified under a zz structure paradigm (developed by Ted Nelson) and it is also aimed towards providing a higher level of abstraction in Petri net specification by providing commands that create more than one Petri net node per command. YPetri documentation is avalable online, but due to formatting issues, you may prefer to generate the documentation on your own by running rdoc in the gem directory. For an example of how YPetri can be used to model complex dynamical systems, see the eukaryotic cell cycle model which I released as "cell_cycle" gem.}
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
