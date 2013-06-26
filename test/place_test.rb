#! /usr/bin/ruby
# -*- coding: utf-8 -*-

require 'minitest/spec'
require 'minitest/autorun'
require_relative '../lib/y_petri'     # tested component itself
# require 'y_petri'
# require 'sy'

describe YPetri::Place do
  before do
    @pç = pç = Class.new YPetri::Place
    @p = pç.new! default_marking: 3.2,
                 marking: 1.1,
                 quantum: 0.1,
                 name: "P1"
  end

  it "should support #name" do
    assert_respond_to @p, :name
    assert_equal @p.name, :P1
  end

  it "should have marking and related methods" do
    @p.marking.must_equal 1.1 # Attention, #marking overloaded with guard setup!
    @p.quantum.must_equal 0.1
    @p.add 1
    @p.value.must_equal 2.1   # near-alias of #marking (no guard setup)
    @p.subtract 0.5
    @p.m.must_equal 1.6       # alias of #value
    @p.reset_marking
    @p.marking.must_equal 3.2
    @p.marking = 42
    @p.m.must_equal 42
    @p.m = 43
    @p.m.must_equal 43
    @p.value = 44
    @p.m.must_equal 44
  end

  it "should have decent #inspect and #to_s methods" do
    assert @p.inspect.start_with? "#<Place:"
    assert @p.to_s.start_with? "#{@p.name}["
  end

  it "should have arc getter methods" do
    @p.upstream_arcs.must_equal []
    @p.upstream_transitions.must_equal [] # alias of #upstream_arcs
    @p.ϝ.must_equal []                    # alias of #upstream_arcs
    @p.downstream_arcs.must_equal []
    @p.downstream_transitions.must_equal [] # alias of #downstream_arcs
    @p.arcs.must_equal [] # all arcs
    @p.precedents.must_equal []
    @p.upstream_places.must_equal [] # alias for #precedents
    @p.dependents.must_equal []
    @p.downstream_places.must_equal [] # alias for #dependents
  end

  it "should have convenience methods to fire surrounding transitions" do
    assert_respond_to @p, :fire_upstream
    assert_respond_to @p, :fire_upstream!
    assert_respond_to @p, :fire_downstream
    assert_respond_to @p, :fire_downstream!
    assert_respond_to @p, :fire_upstream_recursively
    assert_respond_to @p, :fire_downstream_recursively
  end

  it "should have guard mechanics" do
    @p.guards.size.must_equal 2 # working automatic guard construction
    g1, g2 = @p.guards
    g1.assertion.must_include "number"
    g2.assertion.must_include "complex"
    begin; g1.validate 11.1; g2.validate 11.1; @p.guard.( 11.1 ); :nothing_raised
    rescue; :error end.must_equal :nothing_raised
    -> { g2.validate Complex( 1, 1 ) }.must_raise YPetri::GuardError
    @p.marking "must be in 0..10" do |m| fail unless ( 0..10 ) === m end
    @p.guards.size.must_equal 3
    g = @p.federated_guard_closure
    -> { g.( 11.1 ) }.must_raise YPetri::GuardError
    @p.marking = -1.11
    -> { @p.guard! }.must_raise YPetri::GuardError
  end
end
