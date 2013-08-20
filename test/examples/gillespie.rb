#! /usr/bin/ruby
# coding: utf-8

# ==============================================================================
# 
# encoding: utf-8

require 'y_petri'
require 'sy'       # This pathway model uses 'sy' metrology domain model.
require 'mathn'    # Standard library 'mathn' is required.
include YPetri     # pull in the DSL

A = Place m!: 10
B = Place m!: 10
A2B = Transition s: { A: -1, B: 1 }, rate: 0.1
B2A = Transition s: { A: 1, B: -1 }, rate: 0.05

set_step 1 # in seconds
set_target_time 10
set_sampling 1
set_simulation_method :gillespie
sim = new_simulation guarded: false
run!

plot_state
