# encoding: utf-8

# The following are the YSupport components used by YPetri:
require 'y_support/name_magic'         # naming by assignment & more
require 'y_support/unicode'            # ç means self.class
require 'y_support/typing'             # run-time assertions
require 'y_support/core_ext'           # core extensions
require 'y_support/stdlib_ext/matrix'  # matrix extensions
require 'y_support/misc'

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

# YPetri is a domain-specific language (DSL) for modelling dynamical systems. It
# caters solely to the two main concerns of modelling: model specification and
# simulation.
#
# Model specification in YPetri is based on a Petri net. Classical Petri net
# (PN), originally described by Carl Adam Petri in 1962, is a bipartite graph
# with two kinds of nodes: places (circles) and transitions (rectangles),
# connected by arcs (lines). Places act as variables – each place holds exactly
# one value ("marking"), a discrete number imagined as consisting of individual
# units ("tokens"). The action of transitions ("firing") is also discrete. Each
# time a transition fires, a fixed number of tokens is added/subtracted to the
# connected places. It turns out that classical PNs are very useful in describing
# things like industrial systems, production lines, and also basic chemical
# systems with a number of molecules is connected by stoichiometric reactions.
#
# YPetri allows specification of not just classical PNs, but also of many
# extended Petri net (XPN) types, which have been described since Petri's work.
# This is achieved by making YPetri transitions functional (mathematical
# functions in lambda notation can be attached to them), and allowing the
# possibility of transitions being defined as either timed and timeless, and as
# eithier nonstoichiometric and explicitly stoichiometric. Together, this makes 4
# types of functional transitions available in YPetri, which can be used to
# capture almost any type of XPN. In this way, YPetri can serve as a common
# platform for data exchange and cooperation between different XPN formalisms,
# without sacrificing the special qualities of XPNs described thus far.
#
# The basic simulation method is simple PN execution. In its course, transitions
# fire, and thereby change the places' marking by adding/removing tokens as
# dictated by their operating prescription. Other simulation methods become
# available for more specific net types, such as timed nets.
#
module YPetri
  class << self
    def included( receiver )
      receiver.extend YPetri::DSL
      receiver.delegate :y_petri_agent, to: "self.class"
    end
  end
end
