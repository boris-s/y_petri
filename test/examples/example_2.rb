#encoding: utf-8

require 'y_petri'
include YPetri

A = Place( default_marking: 0.5 )
B = Place( default_marking: 0.5 )
A_pump = Transition( stoichiometry: { A: -1 }, rate: proc { 0.005 } )
B_decay = Transition( stoichiometry: { B: -1 }, rate: 0.05 )
net
run!
simulation
places.map &:marking
simulation.settings
print_recording
plot_state; nil
