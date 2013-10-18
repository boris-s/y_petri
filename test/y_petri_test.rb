#! /usr/bin/ruby
# encoding: utf-8

# gem 'minitest', '=4.7.4' # try uncommenting this line if problems appear
require 'minitest/autorun'
require_relative '../lib/y_petri' # tested component itself
# require 'y_petri'
# require 'sy'

# Run all other unit tests.
# 
require_relative 'place_test'
require_relative 'transition_test'
require_relative 'net_test'
require_relative 'simulation_test'
require_relative 'world_test'
require_relative 'agent_test'
