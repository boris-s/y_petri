#! /usr/bin/ruby
# encoding: utf-8

require 'y_petri'
require 'sy'
require 'mathn'
include YPetri

A = Place m!: 10
B = Place m!: 10
AB = Place m!: 0
AB_association = Transition s: { A: -1, B: -1, AB: 1 }, rate: 0.1
AB_dissociation = Transition s: { AB: -1, A: 1, B: 1 }, rate: 0.1
A2B = Transition s: { A: -1, B: 1 }, rate: 0.05
B2A = Transition s: { A: 1, B: -1 }, rate: 0.07

set_step 1
set_target_time 50
set_sampling 1
set_simulation_method :gillespie

run!

print_recording

plot_state
