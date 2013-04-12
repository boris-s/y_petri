# -*- encoding: utf-8 -*-
require File.expand_path('../lib/y_petri/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["boris"]
  gem.email         = ["\"boris@iis.sinica.edu.tw\""]
  gem.description   = %q{a Petri net domain model and simulator}
  gem.summary       = %q{a Petri net domain model and simulator}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "y_petri"
  gem.require_paths = ["lib"]
  gem.version       = YPetri::VERSION
  
  gem.add_dependency "y_support"
  gem.add_dependency "gnuplot"
  gem.add_dependency "ruby-graphviz"
end
