#! /usr/bin/ruby
# -*- coding: utf-8 -*-

require 'minitest/spec'
require 'minitest/autorun'
require_relative '../../lib/y_petri'     # tested component itself
# require 'y_petri'
# require 'sy'

describe "Basic use of TimedSimulation" do
  before do
    @m = YPetri::Manipulator.new
    @m.Place( name: "A", default_marking: 0.5 )
    @m.Place( name: "B", default_marking: 0.5 )
    @m.Transition( name: "A_pump",
                   stoichiometry: { A: -1 },
                   rate: proc { 0.005 } )
    @m.Transition( name: "B_decay",
                   stoichiometry: { B: -1 },
                   rate: 0.05 )
  end

  it "should work" do
    @m.net.must_be_kind_of ::YPetri::Net
    @m.run!
    @m.simulation.must_be_kind_of ::YPetri::Simulation
    @m.plot_state
    sleep 3
  end
end
