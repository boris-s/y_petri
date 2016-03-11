#! /usr/bin/ruby
# encoding: utf-8

gem 'minitest'
require 'minitest/autorun'
require_relative '../lib/y_petri'     # tested component itself
# require 'y_petri'
# require 'sy'

describe "core" do
  before do
    @timed_core_class = YPetri::Core::Timed
    @timeless_core_class = YPetri::Core::Timeless
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
    @timed_core_class::METHODS.keys.must_include :basic
    @timeless_core_class::METHODS.keys.must_include :basic
  end

  describe "timed core" do
  end

  describe "timeless core" do
    describe "basic method" do
      before do
        # @timeless_core_class.new( method: :basic )
        # TODO: The above logically fails, because core now
        # requires simulation. But newly, a core should no
        # longer require a simulation. It should simply receive
        # initial marking vector, information about places
        # (including clamped places and their clamps), information
        # above processes (ie. transitions). Surely, this looks
        # like a third redundant layer of place and transition
        # representations (the first two are in Net and Simulation
        # class). But it serves me right since I want to do things
        # properly :-) Core represents a simulation machine,
        # hardware. Of course, I have no hardware other than
        # Ruby itself. I am not even able to compile the simulation
        # into C. It is quite imaginable that Simulation would
        # be flexible about using cores and simulation methods
        # to do what the user requires it to do, while cores would
        # be more inflexible, method specific and machine specific.
        # So Core is a machine abstraction, while Simulation is the
        # abstraction of what the user might require from a Simulation.
        # Anyway a good way to kill time.
      end

      it "should behave" do
      end
    end
  end
end
