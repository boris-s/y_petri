#! /usr/bin/ruby
# encoding: utf-8

require 'minitest/autorun'
require_relative '../lib/y_petri'     # tested component itself
# require 'y_petri'
# require 'sy'

describe YPetri::Place do
  it "should work" do
    pç = Class.new YPetri::Place
    p = pç.new default_marking: 3.2,
               marking: 1.1,
               quantum: 0.1,
               name: "P1"
    p.namespace.must_equal YPetri::Place
    p.name.must_equal :P1
    p.inspect[0..7].must_equal "#<Place:"
    p.to_s[0..2].must_equal 'P1['
    p.marking.must_equal 1.1 # Attention, #marking overloaded with guard setup!
    p.quantum.must_equal 0.1
    p.add 1
    p.value.must_equal 2.1   # near-alias of #marking (no guard setup)
    p.subtract 0.5
    p.m.must_equal 1.6       # alias of #value
    p.reset_marking
    p.marking.must_equal 3.2
    p.marking = 42
    p.m.must_equal 42
    p.m = 43
    p.m.must_equal 43
    p.value = 44
    p.m.must_equal 44
    p.upstream_arcs.must_equal []
    p.upstream_transitions.must_equal [] # alias of #upstream_arcs
    p.ϝ.must_equal []                    # alias of #upstream_arcs
    p.downstream_arcs.must_equal []
    p.downstream_transitions.must_equal [] # alias of #downstream_arcs
    p.arcs.must_equal [] # all arcs
    p.precedents.must_equal []
    p.upstream_places.must_equal [] # alias for #precedents
    p.dependents.must_equal []
    p.downstream_places.must_equal [] # alias for #dependents
    # fire methods
    assert_respond_to p, :fire_upstream
    assert_respond_to p, :fire_upstream!
    assert_respond_to p, :fire_downstream
    assert_respond_to p, :fire_downstream!
    assert_respond_to p, :fire_upstream_recursively
    assert_respond_to p, :fire_downstream_recursively
    # guard mechanics
    p.guards.size.must_equal 3 # working automatic guard construction
    g1, g2 = p.guards
    [g1.assertion, g2.assertion].tap { |u, v|
      assert u.include?( "number" ) || u.include?( "Numeric" )
      assert v.include?( "complex" ) || v.include?( "Complex" )
    }
    begin; g1.validate 11.1; g2.validate 11.1; p.guard.( 11.1 ); :nothing_raised
    rescue; :error end.must_equal :nothing_raised
    -> { g2.validate Complex( 1, 1 ) }.must_raise YPetri::GuardError
    p.marking "must be in 0..10" do |m| fail unless ( 0..10 ) === m end
    p.guards.size.must_equal 4
    g = p.common_guard_closure
    -> { g.( 11.1 ) }.must_raise YPetri::GuardError
    begin; p.marking = -1.11; rescue YPetri::GuardError => err
      err.message.must_equal 'Marking -1.11:Float of P1 should not be negative!'
    end
  end
end
