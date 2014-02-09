#encoding: utf-8

require 'y_petri'
include YPetri
require 'sy'
require 'mathn'

set_step 10
set_target_time 600
set_sampling 10
# Euler with timeless transitions firing after each step:
set_simulation_method :PseudoEuler

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
plot_recording
