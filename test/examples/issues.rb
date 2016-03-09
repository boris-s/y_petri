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

net.visualize

T1.type
T2.type
net.timed?

net.marking
T1.fire!
net.marking
T2.fire!
net.marking

sim = net.simulation

sim.timed?
sim.simulation_method

sim.marking
sim.step!
sim.marking
sim.step!
sim.marking
sim.reset!
sim.marking










# Whereas this works:

set_step 10
set_target_time 600
set_sampling 10
# Euler with timeless transitions firing after each step:
set_simulation_method :basic

A = Place m!: 1
B = Place m!: 10
C = Place m!: 0

Transition name: :B_disappearing,
           s: { B: -1 },
           action: -> m {  m >= 1 ? 1 : 0 }

Transition name: :C_held_at_half_B,
           domain: :B,
           codomain: :C,
           assignment: -> x { x / 2 }

run!
recording.plot
