#! /usr/bin/ruby
# coding: utf-8

# ==============================================================================
# 
# Thymidine triphosphate pathway model.
# 
# Author: Boris Stitnicky
# Affiliation:
# ... etc etc same shit as in SBML
# 
# ==============================================================================

# === Load the required libraries.
require 'y_nelson' # This pathway model uses FPN domain model.
require 'sy'       # This pathway model uses 'sy' metrology domain model.
require 'mathn'    # Standard library 'mathn' is required.
include YNelson    # pull in the DSL

require "./ttp_pathway/version"             # version number
require './ttp_pathway/michaelis_menten'    # basic function definitions
require './ttp_pathway/general_assumptions' # general model assumptions

# === Load the chosen cell cycle model.
require "./ttp_pathway/simple_cell_cycle"

# === Load the original version of the dTTP pathway based on the literature.
require "./ttp_pathway/literature_model"

# === Simulate it.
set_step 1 # in seconds
set_target_time 24.h.in :s
set_sampling 5.min.in :s
set_simulation_method :pseudo_euler
sim = new_simulation guarded: false
sim.guarded?
sim.run! upto: 10
sim.run! upto: 20
sim.run! upto: 30
sim.run! upto: 40
# FIXME: Here it breaks if step is set to
#     set_step 5 # seconds
# it seems that the problem is actually caused by one of the closures
# returning an incompatible result (imaginary number in this particular case),
# which causes the whole marking vector become imaginary numbers and fail upon
# comparison (#>) subsequently.
#
# The challenge here is to make it easy to debug the models. In execution, I am
# against artificial constraints on place marking, and not just because it slows
# things down, but mainly because such thing is not a part of the Petri net
# business model as I understand it. But at debug time, I am for "type" checking
# that identify the source of problem values. And that should be implemented in
# simulation, in those several #create_*_closures at the end of the class. There
# should be versions of these closures that check the values of the transition
# functions as they are produced and pinpoint where the problem is coming from.
#
# Obviously, YNelson at its current shape has no problems simulating well-written
# nets with good simulation settings
#
# I am not going to program this right now. I'll just look at the simulation
# class, and that will be it for this week. Next programming session: Monday.
sim.run! upto: 50
sim.run! upto: 60
sim.run! upto: 70
sim.run! upto: 80
sim.run! upto: 90
sim.run! upto: 100
sim.run! upto: 1000
sim.run! upto: 10000
sim.run!

sim = new_timed_simulation( guarded: true )
sim.run! upto: 1000
sim.run! upto: 1000

# It turns out that simply, the step was too big

# === Load the acceptance tests for the dTTP pathway behavior.
require_relative "ttp_pathway/acceptance_tests"

# === Run those tests.
test simulation

# === Load the pathway updates according to human judgment.
require_relative "ttp_pathway/model_correction"

# === Rerun the simulation.
run!

# === Run those tests.
test simulation

# Now, having at our disposal a satisfactory dTTP pathway, we can simulate
# its behavior throughout the cell cycle.

# === Rerun the simulation.
run!

# === Visualization suggestions
plot :all, except: Timer # marking of all the FPN places except Timer

plot [ S_phase, A_phase, Cdc20A ] # cell-cycle places marking
plot [ S_phase, A_phase, Cdc20A, TK1, TK1di, TK1tetra, TK1di_P, TMPK ] # TTP pathway concentrations
plot [ S_phase, TK1, TK1di, TK1tetra, TK1di_P ] # TTP pathway enzyme concentrations
plot [ S_phase, Thymidine, TMP, TDP, TTP, T23P ] # TTP patwhay concentrations simplified
plot :flux, except: Clock # all flux except time flow
plot :flux, except: [ Clock, T23P_flux_clamp, TMP_flux_clamp,
                      Thymidine_flux_clamp ] # all except flux clamps
plot :state, except: [ Timer, AMP, ADP, ATP, UTP, UDP, UMP, GMP, DeoxyATP,
                       DeoxyADP, DeoxyAMP, DeoxyCytidine, DeoxyCMP, DeoxyCDP,
                       DeoxyCTP, DeoxyGTP, DeoxyGMP, DeoxyUridine, DeoxyUMP,
                       DeoxyUDP, DeoxyUTP, DeoxyT23P ] # cell cycle marking

# Now let's look into the graph visualization.

# Define function to display it with kioclient
# 
def showit( fɴ )
  system "sleep 0.2; kioclient exec 'file:%s'" %
    File.expand_path( '.', fɴ )
end

# Define enzyme places
enzyme_places = {
  TK1: "TK1",
  TK1di: "TK1 dimer",
  TK1di_P: "TK1 phosphorylated dimer",
  TK1tetra: "TK1 tetramer",
  TMPK: "TMPK"
}

# Define small molecule places
small_molecule_places = {
  Thymidine: "Thymidine",
  TMP: "Thymidine monophosphate",
  T23P: "Thymidine diphosphate / triphosphate pool",
  TDP: "Thymidine diphosphate",
  TTP: "Thymidine triphosphate"
}

# Define graphviz places
def graphviz places
  require 'graphviz'
  γ = GraphViz.new :G, type: :digraph  # Create a new graph

  # # set global node options
  # γ.node[:color] = "#ddaa66"
  # γ.node[:style] = "filled"
  # γ.node[:shape] = "box"
  # γ.node[:penwidth] = "1"
  # γ.node[:fontname] = "Trebuchet MS"
  # γ.node[:fontsize] = "8"
  # γ.node[:fillcolor] = "#ffeecc"
  # γ.node[:fontcolor] = "#775500"
  # γ.node[:margin] = "0.0"

  # # set global edge options
  # γ.edge[:color] = "#999999"
  # γ.edge[:weight] = "1"
  # γ.edge[:fontsize] = "6"
  # γ.edge[:fontcolor] = "#444444"
  # γ.edge[:fontname] = "Verdana"
  # γ.edge[:dir] = "forward"
  # γ.edge[:arrowsize] = "0.5"

  nodes = Hash[ places.map { |pɴ, label|         # make nodes
                  [ pɴ, γ.add_nodes( label ) ]
                } ]

  places.each { |pɴ, label|                      # add edges
    p = place pɴ
    p.upstream_places.each { |up|
      node = nodes[ pɴ ]
      next unless places.map { |ɴ, _| ɴ }.include? up.name
      next if up == p
      upstream_node = nodes[ up.name ]
      upstream_node << node
    }
  }

  γ.output png: "enzymes.png"        # Generate output image
  showit "enzymes.png"
end

[ enzyme_places, small_molecule_places ].each { |ꜧ|
  ꜧ.define_singleton_method :+ do |o| merge o end }

graphviz enzyme_places
graphviz small_molecule_places
graphviz enzyme_places + small_molecule_places # combining pathways

net.visualize


# ==============================================================================
# 
# 1. Please note that the script contained in this file does not constitute
# programming in the sense of software development. It is simply scripted
# user interaction with YPetri FPN simulator. This user interaction takes
# place inside the interactive Ruby session (irb), or it can be saved and
# run all at once as a script. The user has at her disposal the devices and
# language constructs of full-fledged Ruby. The user is not sandboxed (the
# problem of many GUI-based "applications"). In other words, the simulation
# software does not wrap its host language. Rather, it extends Ruby, giving
# its interactive session new, pathway-specific abilities. No constraints
# are placed on how complicated or intelligent the user's use of the software
# can be.
#
# 2. However, on this dTTP pathway model, it can be already noted, that there
# would be certain actions, that the user will have to repeat in most of
# her biological models usin YPetri. For example, Michaelis & Menten function
# definitions are to be expected in many pathway models. More seriously, the
# Petri net models of enzymes and signal proteins suffer exponential explosion
# with number of eligible reactants, competitive inhibitors, and other
# interacting molecules. In typical smaller pathway models, this explosion is
# not deadly, because only few of these interacting molecules are considered.
# But the amount of scripting the user is required to do would still be
# reduced many times, if such enzymes and signal proteins can be expressed
# declaratively, rather than by manual enumeration of their Petri net
# transitions. All of this provides motivation towards developing even more
# concise way of pathway encoding than that provided by plain FPN.
#
# 3. In the planned more concise pathway encoding (that would subsume the
# functionality of the current standards such as SBML), there is one more
# major concern – storing relations. I feel tempted to use Ted Nelson's zz
# structure as an alternative to usual SQL and non-SQL relational databases.
# The usability of zz structures in bioinformatics has already been noted.
# However, I am aware of the advantage held by the existing database merely
# by the virtue of its maturity. To account for the possibility, that my zz
# domain model would become a bottleneck, I will leave the back door open on
# the possibility of using existing database software later on.
# 
# ==============================================================================
