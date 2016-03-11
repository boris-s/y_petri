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

net.timed? # The net is timeless

new_simulation # This produces timed simulation (same as run!)

net.simulation # While this produces timeless simulation.

# This is happening because I have deleted :core selector from
# Simulation class code. I did this because when adding Runge-Kutta
# method, I construct instance-specific instance variable @rk_core
# instead of @core.

# This, again, will produce timed simulation.
net.simulation **ssc

# Simulation#initialize has hard times deciding whether it is
# constructing timed or timeless simulation. When it sees time
# mentioned (:step, :sampling, :time parameters are all set)
# in ssc, it decides to construct a timed simulation.
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


# And here we fail for real

require 'y_petri'
include YPetri

A = Place default_marking: 5
B = Place default_marking: 5
C = Place default_marking: 0
D = Place default_marking: 0

T1 = Transition stoichiometry: { A: -1, B: -1, C: 1 }
T2 = Transition stoichiometry: { C: -1, D: 1 }

sim = net.simulation # constructs a timeless simulation

# run! should warn about making timed simulation, perhaps
# so that the users are not confused
# it is quite convenient that YPetri is smart to make
# a timed simulation when calling run! upon a timeless net,
# but the user might not expect it

sim.simulation_method # should be :basic
sim.marking             #=> [5, 5, 0, 0]

# And here we fail for real.

sim.step!

# Later, I should investigate why.

sim.marking             #=> [4, 4, 0, 1]
sim.step!
sim.marking             #=> [3, 3, 0, 2]
