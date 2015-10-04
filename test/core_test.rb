#! /usr/bin/ruby
# encoding: utf-8

gem 'minitest'
require 'minitest/autorun'
require_relative '../lib/y_petri'     # tested component itself
# require 'y_petri'
# require 'sy'

describe "use of timed and timeless core" do
  before do
    # set up a user of core, which will imitate some of the needs
    # of the Simulation class, or be an actual instance of that class
  end

  it "should behave" do
    # the core will be informed of the task required (bring the system
    # whose specification is known to the core user mentioned above from
    # some initial state to some next state by performing a requested
    # something in a way requested by the user, where something can be
    # eg. step forward, or run forward by a specified period of time or
    # number of steps or until some other condition is fulfilled, or
    # step backward, or even run backward, if the system allows such thing
    # at all.
  end
end
