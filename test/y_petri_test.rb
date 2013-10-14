#! /usr/bin/ruby
# encoding: utf-8

# gem 'minitest', '=4.7.4' # try uncommenting this line if problems appear
require 'minitest/autorun'
require_relative '../lib/y_petri' # tested component itself
# require 'y_petri'
# require 'sy'

# Unit tests for the YPetri module.
# 
describe YPetri do
  it "should have basic classes" do
    [ :Place, :Transition, :Net, :Simulation, :World, :Agent ]
      .each { |ß| YPetri.const_get( ß ).must_be_kind_of Module }
  end
end

# Run all other unit tests.
# 
require_relative 'place_test'
require_relative 'transition_test'
require_relative 'net_test'
require_relative 'simulation_test'
require_relative 'world_test'
require_relative 'agent_test'
