#! /usr/bin/ruby
# -*- coding: utf-8 -*-

require 'minitest/spec'
require 'minitest/autorun'
require_relative '../lib/y_petri'     # tested component itself
# require 'y_petri'
# require 'sy'

# Unit tests for the YPetri module.
# 
describe YPetri do
  it "should have basic classes" do
    [ :Place, :Transition, :Net, :Simulation, :Workspace, :Manipulator ]
      .each { |ß| YPetri.const_get( ß ).must_be_kind_of Module }
  end
end

# Run all other unit tests.
# 
require_relative 'place_test'
require_relative 'transition_test'
require_relative 'net_test'
require_relative 'simulation_test'
require_relative 'timed_simulation_test'
require_relative 'workspace_test'
require_relative 'manipulator_test'
