#! /usr/bin/ruby
# -*- coding: utf-8 -*-

require 'minitest/spec'
require 'minitest/autorun'
require_relative '../lib/y_petri'     # tested component itself
# require 'y_petri'
# require 'sy'

describe ::YPetri::Simulation do
  before do
    @pç = pç = Class.new( ::YPetri::Place )
    @tç = tç = Class.new( ::YPetri::Transition )
    @nç = nç = Class.new( ::YPetri::Net )
    [ @pç, @tç, @nç ].each { |klass|
      klass.namespace!
      klass.class_exec {
        private
        define_method :Place do pç end
        define_method :Transition do tç end
        define_method :Net do nç end
      }
    }
    @p1 = @pç.new name: "P1", default_marking: 1
    @p2 = @pç.new name: "P2", default_marking: 2
    @p3 = @pç.new name: "P3", default_marking: 3
    @p4 = @pç.new name: "P4", default_marking: 4
    @p5 = @pç.new name: "P5", default_marking: 5
    @t1 = @tç.new name: "T1",
                  s: { @p1 => -1, @p2 => -1, @p4 => 1 },
                  rate: 0.1
    @t2 = @tç.new name: "T2",
                  s: { @p1 => -1, @p3 => 1 },
                  rate: -> a { a * 0.5 }
    @t3 = @tç.new name: "T3",
                  s: { @p1 => -1, @p2 => -1, @p4 => 1 },
                  domain: @p3,
                  rate: -> a { a * 0.5 }
    @net = @nç.new << @p1 << @p2 << @p3 << @p4 << @p5
    @net.include_transition! @t1
    @net.include_transition! @t2
    @net << @t3
    @s = YPetri::Simulation.new net: @net,
                                marking_clamps: { @p1 => 2.0, @p5 => 2.0 },
                                initial_marking: { @p2 => @p2.default_marking,
                                                   @p3 => @p3.default_marking,
                                                   @p4 => @p4.default_marking }
  end

  it "exposes the net" do
    @s.net.must_equal @net
    @s.net.places.size.must_equal 5
    @s.net.transitions.size.must_equal 3
    assert @net.include? @t1
    assert @s.net.include? @t1
    assert @net.include? @t2
    assert @s.net.include? @t2
    assert @net.include? @t3
    assert @s.net.include? @t3
    @s.net.transitions.size.must_equal 3
  end

  it "exposes Petri net places" do
    @s.places.map( &:source ).must_equal [ @p1, @p2, @p3, @p4, @p5 ]
    @s.pn.must_equal [ :P1, :P2, :P3, :P4, :P5 ]
  end

  it "exposes Petri net transitions" do
    @s.transitions.map( &:source ).must_equal [ @t1, @t2, @t3 ]
    @s.tn.must_equal [ :T1, :T2, :T3 ]
  end

  it "exposes place clamps" do
    @s.marking_clamps.values.must_equal [2, 2]
    @s.n_clamped.must_equal [:P1, :P5]
  end

  it "presents free places" do
    @s.free_places.map( &:source ).must_equal [ @p2, @p3, @p4 ]
    @s.n_free.must_equal [ :P2, :P3, :P4 ]
  end

  it "presents clamped places" do
    @s.n_clamped.must_equal [ :P1, :P5 ]
    @s.clamped_places.map( &:source ).must_equal [ @p1, @p5 ]
  end

  it "exposes initial marking" do
    ( @s.free_places.map( &:source ) >> @s.im( *@s.free_places ) )
      .must_equal( { @p2 => 2, @p3 => 3, @p4 => 4 } )
    ( @s.n_free >> @s.im( *@s.free_places ) )
        .must_equal( { P2: 2, P3: 3, P4: 4 } )
    @s.im.must_equal [ 2, 3, 4 ]
    @s.im_vector.must_equal Matrix[[2], [3], [4]]
    @s.im_vector.must_equal @s.iᴍ
  end

  it "exposes marking (simulation state)" do
    @s.marking.must_equal [2, 3, 4] # (we're after reset)
    @s.free_places( :m ).must_equal( { @p2 => 2, @p3 => 3, @p4 => 4 } )
    @s.free_pp( :m ).must_equal( { P2: 2, P3: 3, P4: 4 } )
    @s.ᴍ.must_equal Matrix[[2], [3], [4]]
  end

  it "separately exposes marking of clamped places" do
    @s.m( *@s.clamped_places ).must_equal [ 2, 2 ]
    @s.clamped_places( :m_clamped ).must_equal( { @p1 => 2, @p5 => 2 } )
    @s.clamped_pp( :m_clamped ).must_equal( { P1: 2, P5: 2 } )
    @s.ᴍ_clamped.must_equal Matrix[[2], [2]]
  end

  it "exposes marking of all places (with capitalized M)" do
    @s.pn.must_equal [:P1, :P2, :P3, :P4, :P5]
    @s.m.must_equal [ 2, 2, 3, 4, 2 ]
    ( @s.places >> @s.m( *@s.places ) )
      .must_equal( { @p1 => 2, @p2 => 2, @p3 => 3, @p4 => 4, @p5 => 2 } )
    @s.marking_vector.must_equal Matrix[[2], [2], [3], [4], [2]]
  end

  it "has stoichiometry matrix for 3. tS transitions" do
    @s.tS_stoichiometry_matrix.must_equal Matrix.empty( 3, 0 )
    @s.tS_SM.must_equal Matrix.empty( 3, 0 )
  end

  it "has stoichiometry matrix for 6. TS transitions" do
    @s.TS_SM.must_equal Matrix[[-1,  0, -1], [0, 1, 0], [1, 0, 1]]
    @s.SM.must_equal @s.TS_SM
  end

  it "presents 1. TS transitions" do
    assert_equal [@t1, @t2, @t3], @s.TS_transitions.map( &:source )
    assert_equal( { @t1 => :T1, @t2 => :T2, @t3 => :T3 },
                  @s.TS_transitions.map( &:source ) >> @s.n_TS )
    assert_equal [:T1, :T2, :T3], @s.n_TS
  end

  it "presents 2. Ts transitions" do
    assert_equal [], @s.Ts_transitions
    assert_equal [], @s.n_Ts
  end

  it "presents 3. tS transitions" do
    assert_equal [], @s.tS_transitions
    assert_equal [], @s.n_tS
  end

  it "presents 4. ts transitions" do
    assert_equal [], @s.ts_transitions
    assert_equal [], @s.n_ts
  end

  it "presents A transitions" do
    assert_equal [], @s.A_transitions
    assert_equal [], @s.n_A
  end

  it "presents S transitions" do
    assert_equal [@t1, @t2, @t3], @s.S_transitions.map( &:source )
    assert_equal [:T1, :T2, :T3], @s.n_S
  end

  it "presents s transitions" do
    assert_equal [], @s.s_transitions
    assert_equal [], @s.n_s
  end

  it "1. handles TS transitions" do
    @s.transitions.TS.rate_closures.size.must_equal 3
    @s.transitions.TS.flux_vector.must_equal Matrix.column_vector( [ 0.4, 1.0, 1.5 ] )
    @s.φ_for_SR.must_equal @s.flux_vector
    @s.SR_tt( :φ_for_SR ).must_equal( { T1: 0.4, T2: 1.0, T3: 1.5 } )
    @s.first_order_action_vector_for_SR( 1 )
      .must_equal Matrix.column_vector [ 0.4, 1.0, 1.5 ]
    @s.SR_tt( :first_order_action_for_SR, 1 ).must_equal( T1: 0.4, T2: 1.0, T3: 1.5 )
    @s.Δ_SR( 1 ).must_equal Matrix[[-1.9], [1.0], [1.9]]
    @s.free_pp( :Δ_SR, 1 ).must_equal( { P2: -1.9, P3: 1.0, P4: 1.9 } )
  end

  it "2. handles Ts transitions" do
    assert_equal [], @s.transitions.Ts.gradient_closures
    @s.transitions.Ts.delta( 1.0 ).must_equal Matrix.zero( @s.n_free.size, 1 )
  end

  it "3. handles tS transitions" do
    @s.transitions.tS.firing_closures.must_equal []
    @s.transitions.tS.firing_vector.must_equal Matrix.column_vector( [] )
    @s.transitions.tS.delta.must_equal Matrix.zero( @s.n_free.size, 1 )
  end

  it "1. handles ts transitions" do
    @s.transitions.ts.delta_closures.must_equal []
  end

  it "presents sparse stoichiometry vectors for its transitions" do
    @s.transition( @t1 ).sparse_sv.must_equal Matrix.cv( [-1, 0, 1] )
    @s.sparse_stoichiometry_vector( of: @t1 )
      .must_equal Matrix.cv( [-1, -1, 0, 1, 0] )
  end

  it "presents correspondence matrices free, clamped => all places" do
    @s.f2a.must_equal Matrix[[0, 0, 0], [1, 0, 0], [0, 1, 0],
                                    [0, 0, 1], [0, 0, 0]]
    @s.c2a.must_equal Matrix[[1, 0], [0, 0], [0, 0], [0, 0], [0, 1]]
  end
end
