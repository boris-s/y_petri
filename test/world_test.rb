#! /usr/bin/ruby
# encoding: utf-8

gem 'minitest'
require 'minitest/autorun'
require_relative '../lib/y_petri'     # tested component itself
# require 'y_petri'
# require 'sy'

describe YPetri::World do
  before do
    @w = YPetri::World.new
    a = @w.Place.new( default_marking: 1.0, name: "AA", avid: true )
    b = @w.Place.new( default_marking: 2.0, name: "BB", avid: true )
    c = @w.Place.new( ɴ: "CC", avid: true, default_marking: 3.0 )
    t1 = @w.Transition.new s: { a => -1, b => -1, c => 1 },
                           rate: 0.1,
                           ɴ: "AA_BB_assembly",
                           avid: true
    t2 = @w.Transition.new ɴ: "AA_appearing",
                           avid: true,
                           codomain: a,
                           rate: -> { 0.1 },
                           stoichiometry: 1
    @pp, @tt = [a, b, c], [t1, t2]
    @f_name = "test_output.csv"
    @w.set_imc @pp >> @pp.map( &:default_marking )
    @w.set_ssc step: 0.1, sampling: 10, time: 0..50
    @w.set_cc( {} )
    @sim = @w.new_simulation
    File.delete @f_name rescue nil
  end

  it "should present places, transitions, nets, simulations" do
    assert_kind_of YPetri::Net, @w.Net.instance( :Top )
    assert_equal @pp[0], @w.place( "AA" )
    assert_equal @tt[0], @w.transition( "AA_BB_assembly" )
    assert_equal @pp, @w.places
    assert_equal @tt, @w.transitions
    assert_equal 1, @w.nets.size
    assert_equal 1, @w.simulations.size
    assert_equal 0, @w.cc.size
    assert_equal 3, @w.imc.size
    assert [0.1, 10, 50].each { |e| @w.ssc.include? e }
    assert_equal @sim, @w.simulation
    assert_equal [:Base], @w.clamp_collections.keys
    assert_equal [:Base], @w.initial_marking_collections.keys
    assert_equal [:Base], @w.simulation_settings_collections.keys
    assert_equal [:AA, :BB, :CC], @w.places.names
    assert_equal [:AA_BB_assembly, :AA_appearing], @w.transitions.names
    assert_equal [:Top], @w.nets.names
  end

  it "should simulate" do
    assert_equal 1, @w.simulations.size
    assert_kind_of( YPetri::Simulation, @w.simulation )
    assert_equal 2, @w.simulation.TS_tt.size
    @tt[0].domain.must_equal [ @pp[0], @pp[1] ]
    @tt[1].domain.must_equal []
    assert @w.simulation.timed?
    assert_equal [0.2, 0.1], @w.simulation.flux_vector.column_to_a
    @w.simulation.step!
    @w.simulation.run!
    rec_csv = @w.simulation.recording.to_csv
    expected_rec_csv =
      ":event,:AA,:BB,:CC\n" +
      "0.0,1.0,2.0,3.0\n" +
      "10.0,0.86102,0.86102,4.13898\n" +
      "20.0,1.29984,0.29984,4.70016\n"
    rec_csv.to_s[0, expected_rec_csv.size].must_equal expected_rec_csv
  end
end
