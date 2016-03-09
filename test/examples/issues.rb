#encoding: utf-8

# Found things that do not work with YPetri. 

require 'y_petri'
include YPetri

A = Place default_marking: 5
B = Place default_marking: 5
C = Place default_marking: 0
D = Place default_marking: 0

T1 = Transition stoichiometry: { A: -1, B: -1, C: 1 }
T2 = Transition stoichiometry: { C: -1, D: 1 }

net.timed?

# This works
new_simulation # Calls agent.new_simulation, which in turn
               # calls world.new_simulation, which proceeds
               # to call Net#simulation method on Top net.

# But this doesn't
net.simulation
# Oh, sorry, it already does, but it produces timeless simulation,
# while new_simulation produces timed simulation.

# This is happening since I have deleted :core selector from
# Simulation class code. I don't know where is the difference.

# All right, I know where the problem is. Or rather, this is
# not really a problem. For once, this will produce timed simulation:

net.simulation **ssc

# The reason why this happens is because Simulation#initialize
# has hard times to decide whether it is constructing a timed
# or timeless simulation. When it sees time mentioned (:step,
# :sampling, :time parameters are all set) in ssc, it decides
# to construct a timed simulation.
#
# When it does not see the time mentioned, it decides to construct
# a timeless simulation. The decision is quite right when I merely
# call net.simulation, because the net is actually quite timeless.
#
# But once I call for :basic simulation method ...
#
# Now I used to call :basic method :pseudo_euler, which would suggest
# timed simulation. But timeless simulations also have :basic method
# among them...
#
# The question is whether I should have timed and timeless methods
# with same names...

# I should keep at this and rethink the Simulation class



# also, another problem
# 
# set_ssc :Hello
# 
# instead of trying to set the simulation settings collection
# to the one named :Hello will cause the simulation settings
# collection named :Base be set to :Hello

simulation_settings_collection # alias ssc

simulation_settings_collections

set_simulation_settings_collection :Hello

simulation_settings_collection # alias ssc

simulation_settings_collections

# This is obviously wrong. Whole idea of collections of clamps
# and initial values and simulation settings is quite dated, it
# dates back to the times when I was not at the top of my Ruby
# proficiency yet. Maybe time to rethink World / Agent classes.
