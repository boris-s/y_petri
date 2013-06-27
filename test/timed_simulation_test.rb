#! /usr/bin/ruby
# -*- coding: utf-8 -*-

require 'minitest/spec'
require 'minitest/autorun'
require_relative '../lib/y_petri'     # tested component itself
# require 'y_petri'
# require 'sy'

include Pyper if require 'pyper'

# **************************************************************************
# Test of TimedSimulation class.
# **************************************************************************
#
describe YPetri::TimedSimulation do  
  before do
    # skip "to speed up testing"
    @a = YPetri::Place.new default_marking: 1.0
    @b = YPetri::Place.new default_marking: 2.0
    @c = YPetri::Place.new default_marking: 3.0
  end

  describe "timed assembly a + b >> c" do
    before do
      @t1 = YPetri::Transition.new s: { @a => -1, @b => -1, @c => 1 }, rate: 0.1
      @net = YPetri::Net.new << @a << @b << @c << @t1
      @im_collection = [@a, @b, @c].τBmχHτ &:default_marking
    end

    describe "simulation with step size 1" do
      before do
        @sim = YPetri::TimedSimulation.new net: @net,
                                           initial_marking: @im_collection,
                                           step: 1,
                                           sampling: 10,
                                           target_time: 100
      end

      it "should #step! with expected results" do
        m = @sim.step!.marking
        assert_in_delta 0.8, m[ 0 ], 1e-9
        assert_in_delta 1.8, m[ 1 ], 1e-9
        assert_in_delta 3.2, m[ 2 ], 1e-9
      end

      it "should behave" do
        assert_in_delta 0, ( Matrix.column_vector( [-0.02, -0.02, 0.02] ) -
                             @sim.ΔE( 0.1 ) ).column( 0 ).norm, 1e-9
        @sim.step! 0.1
        assert_in_delta 0, ( Matrix.column_vector( [0.98, 1.98, 3.02] ) -
                             @sim.marking_vector ).column( 0 ).norm, 1e-9

      end
    end

    describe "simulation with step size 0.1" do
      before do
        @sim = YPetri::TimedSimulation.new net: @net,
                                           initial_marking: @im_collection,
                                           step: 0.1,
                                           sampling: 10,
                                           target_time: 100
      end

      it "should behave" do
        m = @sim.step!.marking
        assert_equal 10, @sim.sampling_period
        assert_in_delta 0.98, m[ 0 ], 1e-9
        assert_in_delta 1.98, m[ 1 ], 1e-9
        assert_in_delta 3.02, m[ 2 ], 1e-9
      end

      it "should behave" do
        @sim.run_until_target_time! 31
        expected_recording = {
          0 => [ 1, 2, 3 ],
          10 => [ 0.22265, 1.22265, 3.77735 ],
          20 => [ 0.07131, 1.07131, 3.92869 ],
          30 => [ 0.02496, 1.02496, 3.97503 ]
        }
        assert_equal expected_recording.keys, @sim.recording.keys
        assert_in_delta 0, expected_recording.values.zip( @sim.recording.values )
          .map{ |expected, actual| ( Vector[ *expected ] -
                                     Vector[ *actual ] ).norm }.reduce( :+ ), 1e-4
        expected_recording_string =
          "0.0,1.0,2.0,3.0\n" +
          "10.0,0.22265,1.22265,3.77735\n" +
          "20.0,0.07131,1.07131,3.92869\n" +
          "30.0,0.02496,1.02496,3.97504\n"
        assert_equal expected_recording_string, @sim.recording_csv_string
      end
    end
  end

  describe "timed 'isomerization' with given as λ" do
    before do
      @t2 = YPetri::Transition.new s: { @a => -1, @c => 1 },
                                     rate_closure: -> a { a * 0.5 }
      @net = YPetri::Net.new << @a << @b << @c << @t2
    end

    describe "behavior of #step" do
      before do
        @sim = YPetri::TimedSimulation.new net: @net,
                 initial_marking: [ @a, @b, @c ].τBᴍHτ( &:default_marking ),
                 step: 1,
                 sampling: 10
      end

      it "should have expected stoichiometry matrix" do
        @sim.S.must_equal Matrix[ [-1, 0, 1] ].t
        m = @sim.step!.marking
        m[ 0 ].must_be_within_epsilon( 0.5, 1e-6 )
        m[ 1 ].must_equal 2
        m[ 2 ].must_be_within_delta( 3.5, 1e-9 )
      end
    end
  end

  describe "timed controlled isomerization" do
    before do
      @t3 = YPetri::Transition.new s: { @a => -1, @c => 1 },
                                     domain: @b,
                                     rate: -> a { a * 0.5 }
      @net = YPetri::Net.new << @a << @b << @c << @t3
      @sim = YPetri::TimedSimulation.new net: @net,
               initial_marking: { @a => 1, @b => 0.6, @c => 3 },
               step: 1,
               sampling: 10,
               target_time: 2
    end

    it "should exhibit correct behavior of #step" do
      @sim.marking.must_equal [1.0, 0.6, 3.0]
      @t3.stoichiometric?.must_equal true
      @t3.timed?.must_equal true
      @t3.has_rate?.must_equal true
      @sim.gradient.must_equal Matrix.cv [-0.3, 0.0, 0.3]
      @sim.Δ_Euler.must_equal Matrix.cv [-0.3, 0.0, 0.3]
      @sim.step!
      @sim.marking_vector.must_equal Matrix.cv [0.7, 0.6, 3.3]
      @sim.euler_step!
      @sim.run!
      @sim.marking_vector.map( &[:round, 5] )
        .must_equal Matrix.cv [0.4, 0.6, 3.6]
    end
  end
end
