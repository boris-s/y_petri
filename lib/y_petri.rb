# encoding: utf-8

# The following are the YSupport components used by YPetri:
require 'y_support/local_object'       # object aware of its creation scope
require 'y_support/respond_to'         # Symbol#~@ + RespondTo#===
require 'y_support/name_magic'         # naming by assignment & more
require 'y_support/unicode'            # ç means self.class
require 'y_support/typing'             # run-time assertions
require 'y_support/try'                # increased awareness in danger
require 'y_support/core_ext'           # core extensions
require 'y_support/stdlib_ext/matrix'  # matrix extensions
require 'y_support/abstract_algebra'   # 
require 'y_support/kde'                # popup file with kioclient

# ActiveSupport components:
require 'active_support/core_ext/module/delegation'
require 'active_support/core_ext/array/extract_options'
require 'active_support/inflector'

# The following are the Ruby libraries used by YPetri:
require 'gnuplot'                      # used for graph visualization
require 'csv'                          # not used at the moment
require 'graphviz'                     # used for Petri net visualization
require 'pp'                           # usef for pretty
require 'distribution'                 # used in the simulation core

require_relative 'y_petri/version'
require_relative 'y_petri/fixed_assets'
require_relative 'y_petri/world'
require_relative 'y_petri/place'
require_relative 'y_petri/transition'
require_relative 'y_petri/net'
require_relative 'y_petri/simulation'
require_relative 'y_petri/core'
require_relative 'y_petri/agent'
require_relative 'y_petri/dsl'

# YPetri is a domain model and a domain-specific language (DSL) for modelling of
# dynamical systems. YPetri module contains a collection of assets for Petri
# net-based model specification and its simulation.
#
# A Petri net (PN) is a bipartite graph with two kinds of nodes: places and
# transitions. Places are visualised as circles, transitions as rectangles. Arcs
# connecting places and transitions are visualised as lines, but these are not
# considered first class citizens in YPetri abstraction.
#
# During PN execution (simulation), transitions act upon places and change their
# marking by adding / removing tokens as dictated by the prescription of their
# operation. This can be done by attaching a function to the transition. Such
# transitions are called functional transitions in YPetri. Borrowing more from
# the functional terminology, YPetri defines keywords domain an codomain for
# a PN transition in a way similar to the domain and codomain of a function.
#
# YPetri unifies discrete and stochastic modelling of timed transitions at the
# level of model specification in line with the present day unifying Petri net
# frameworks. YPetri also integrates other dichotomies: timed / timeless and
# stoichiometric / nonstoichiometric.
# 
module YPetri
  class << self
    def included( receiver )
      receiver.extend YPetri::DSL
      receiver.delegate :y_petri_agent, to: "self.class"
    end
  end
end
