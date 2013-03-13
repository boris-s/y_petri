#encoding: utf-8

require 'y_petri'
include YPetri
require 'sy'
require 'mathn'

set_step 10
set_target_time 600
set_sampling 10
set_simulation_method :Euler_with_timeless_transitions_firing_after_each_step

A = Place m!: 1
B = Place m!: 10
C = Place m!: 0

Transition name: :B_disappearing,
           s: { B: -1 },
           action: lambda { |m| 1 if m >= 1 }

run!
plot_recording
