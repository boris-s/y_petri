#! /usr/bin/ruby
# encoding: utf-8

gem 'minitest', '=4.7.4'
require 'minitest/autorun'
require_relative '../lib/y_petri'     # tested component itself
# require 'y_petri'
# require 'sy'

require_relative 'acceptance/token_game_test'
require_relative 'acceptance/basic_usage_test'
require_relative 'acceptance/simulation_test'
require_relative 'acceptance/visualization_test'
require_relative 'acceptance/simulation_with_physical_units_test'
