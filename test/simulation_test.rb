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
    @s.places.must_equal [ @p1, @p2, @p3, @p4, @p5 ]
    @s.pp.must_equal [ :P1, :P2, :P3, :P4, :P5 ]
    @s.places( :pp ).must_equal( { @p1 => :P1, @p2 => :P2, @p3 => :P3,
                                   @p4 => :P4, @p5 => :P5 } )
    @s.pp( :pp ).must_equal( { P1: :P1, P2: :P2, P3: :P3, P4: :P4, P5: :P5 } )
  end

  it "exposes Petri net transitions" do
    @s.transitions.must_equal [ @t1, @t2, @t3 ]
    @s.tt.must_equal [ :T1, :T2, :T3 ]
    @s.transitions( :tt ).must_equal( { @t1 => :T1, @t2 => :T2, @t3 => :T3 } )
    @s.tt( :tt ).must_equal( { T1: :T1, T2: :T2, T3: :T3 } )
  end

  it "exposes place clamps" do
    @s.clamped_places( :place_clamps ).must_equal( { @p1 => 2, @p5 => 2 } )
    @s.clamped_pp( :place_clamps ).must_equal( { P1: 2, P5: 2 } )
  end

  it "presents free places" do
    @s.free_places.must_equal [ @p2, @p3, @p4 ]
    @s.free_pp.must_equal [ :P2, :P3, :P4 ]
    @s.free_places( :free_pp )
      .must_equal( { @p2 => :P2, @p3 => :P3, @p4 => :P4 } )
    @s.free_pp( :free_pp )
      .must_equal( { P2: :P2, P3: :P3, P4: :P4 } )
  end

  it "presents clamped places" do
    @s.clamped_places.must_equal [ @p1, @p5 ]
    @s.clamped_pp.must_equal [ :P1, :P5 ]
    @s.clamped_places( :clamped_pp ).must_equal( { @p1 => :P1, @p5 => :P5 } )
    @s.clamped_pp( :clamped_pp ).must_equal( { P1: :P1, P5: :P5 } )
  end

  it "exposes initial marking" do
    @s.free_places( :im ).must_equal( { @p2 => 2, @p3 => 3, @p4 => 4 } )
    @s.free_pp( :im ).must_equal( { P2: 2, P3: 3, P4: 4 } )
    @s.im.must_equal [ 2, 3, 4 ]
    @s.im_vector.must_equal Matrix[[2], [3], [4]]
    @s.im_vector.must_equal @s.iᴍ
  end

  it "exposes marking (simulation state)" do
    @s.m.must_equal [2, 3, 4] # (we're after reset)
    @s.free_places( :m ).must_equal( { @p2 => 2, @p3 => 3, @p4 => 4 } )
    @s.free_pp( :m ).must_equal( { P2: 2, P3: 3, P4: 4 } )
    @s.ᴍ.must_equal Matrix[[2], [3], [4]]
  end

  it "separately exposes marking of clamped places" do
    @s.m_clamped.must_equal [ 2, 2 ]
    @s.clamped_places( :m_clamped ).must_equal( { @p1 => 2, @p5 => 2 } )
    @s.clamped_pp( :m_clamped ).must_equal( { P1: 2, P5: 2 } )
    @s.ᴍ_clamped.must_equal Matrix[[2], [2]]
  end

  it "exposes marking of all places (with capitalized M)" do
    @s.marking.must_equal [ 2, 2, 3, 4, 2 ]
    @s.places( :marking )
      .must_equal( { @p1 => 2, @p2 => 2, @p3 => 3, @p4 => 4, @p5 => 2 } )
    @s.pp( :marking ).must_equal( { P1: 2, P2: 2, P3: 3, P4: 4, P5: 2 } )
    @s.marking_vector.must_equal Matrix[[2], [2], [3], [4], [2]]
  end

  it "has #S_for / #stoichiometry_matrix_for" do
    assert_equal Matrix.empty(3, 0), @s.S_for( [] )
    assert_equal Matrix[[-1], [0], [1]], @s.S_for( [@t1] )
    x = Matrix[[-1, -1], [0, 0], [1, 1]]
    x.must_equal @s.S_for( [@t1, @t3] )
    x.must_equal( @s.S_for( [@t1, @t3] ) )
    @s.stoichiometry_matrix_for( [] ).must_equal Matrix.empty( 5, 0 )
  end

  it "has stoichiometry matrix for 3. tS transitions" do
    @s.S_tS.must_equal Matrix.empty( 3, 0 )
  end

  it "has stoichiometry matrix for 4. Sr transitions" do
    @s.S_TSr.must_equal Matrix.empty( 3, 0 )
  end

  it "has stoichiometry matrix for 6. SR transitions" do
    @s.S_SR.must_equal Matrix[[-1,  0, -1], [0, 1, 0], [1, 0, 1]]
    @s.S.must_equal @s.S_SR
  end

  it "presents 1. ts" do
    assert_equal [], @s.ts_transitions
    assert_equal( {}, @s.ts_transitions( :ts_transitions ) )
    assert_equal [], @s.ts_tt
    assert_equal( {}, @s.ts_tt( :ts_tt ) )
  end

  it "presents 2. tS transitions" do
    assert_equal [], @s.tS_transitions
    assert_equal( {}, @s.tS_transitions( :tS_transitions ) )
    assert_equal [], @s.tS_tt
    assert_equal( {}, @s.tS_tt( :tS_tt ) )
  end

  it "presents 3. Tsr transitions" do
    assert_equal [], @s.Tsr_transitions
    assert_equal( {}, @s.Tsr_transitions( :Tsr_transitions ) )
    assert_equal [], @s.Tsr_tt
    assert_equal( {}, @s.Tsr_tt( :Tsr_tt ) )
  end

  it "presents 4. TSr transitions" do
    assert_equal [], @s.TSr_transitions
    assert_equal( {}, @s.TSr_transitions( :TSr_tt ) )
    assert_equal [], @s.TSr_tt
    assert_equal( {}, @s.TSr_tt( :TSr_tt ) )
  end

  it "presents 5. sR transitions" do
    assert_equal [], @s.sR_transitions
    assert_equal( {}, @s.sR_transitions( :sR_transitions ) )
    assert_equal [], @s.sR_tt
    assert_equal( {}, @s.sR_tt( :sR_tt ) )
  end

  it "presents SR transitions" do
    assert_equal [@t1, @t2, @t3], @s.SR_transitions
    assert_equal( { @t1 => :T1, @t2 => :T2, @t3 => :T3 },
                  @s.SR_transitions( :SR_tt ) )
    assert_equal [:T1, :T2, :T3], @s.SR_tt
    assert_equal( { T1: :T1, T2: :T2, T3: :T3 }, @s.SR_tt( :SR_tt ) )
  end

  it "presents A transitions" do
    assert_equal [], @s.A_transitions
    assert_equal( {}, @s.A_transitions( :A_tt ) )
    assert_equal [], @s.A_tt
    assert_equal( {}, @s.A_tt( :A_tt ) )
  end

  it "presents S transitions" do
    assert_equal [@t1, @t2, @t3], @s.S_transitions
    assert_equal [:T1, :T2, :T3], @s.S_tt
    assert_equal( { T1: :T1, T2: :T2, T3: :T3 }, @s.S_tt( :S_tt ) )
  end

  it "presents s transitions" do
    assert_equal [], @s.s_transitions
    assert_equal [], @s.s_tt
    assert_equal( {}, @s.s_tt( :s_tt ) )
  end

  it "presents R transitions" do
    assert_equal [@t1, @t2, @t3], @s.R_transitions
    assert_equal [:T1, :T2, :T3], @s.R_tt
    assert_equal( { T1: :T1, T2: :T2, T3: :T3 }, @s.R_tt( :R_tt ) )
  end

  it "presents r transitions" do
    assert_equal [], @s.r_transitions
    assert_equal [], @s.r_tt
  end

  it "1. handles ts transitions" do
    @s.Δ_closures_for_tsa.must_equal []
    @s.Δ_if_tsa_fire_once.must_equal Matrix.zero( @s.free_pp.size, 1 )
  end

  it "2. handles Tsr transitions" do
    @s.Δ_closures_for_Tsr.must_equal []
    @s.Δ_Tsr( 1.0 ).must_equal Matrix.zero( @s.free_pp.size, 1 )
  end

  it "3. handles tS transitions" do
    @s.action_closures_for_tS.must_equal []
    @s.action_vector_for_tS.must_equal Matrix.column_vector( [] )
    @s.ᴀ_t.must_equal Matrix.column_vector( [] )
    @s.Δ_if_tS_fire_once.must_equal Matrix.zero( @s.free_pp.size, 1 )
  end

  it "4. handles TSr transitions" do
    @s.action_closures_for_TSr.must_equal []
    @s.action_closures_for_Tr.must_equal []
    @s.action_vector_for_TSr( 1.0 ).must_equal Matrix.column_vector( [] )
    @s.action_vector_for_Tr( 1.0 ).must_equal Matrix.column_vector( [] )
    @s.Δ_TSr( 1.0 ).must_equal Matrix.zero( @s.free_pp.size, 1 )
  end

  it "5. handles sR transitions" do
    assert_equal [], @s.rate_closures_for_sR
    assert_equal [], @s.rate_closures_for_s
    # @s.gradient_for_sR.must_equal Matrix.zero( @s.free_pp.size, 1 )
    @s.Δ_sR( 1.0 ).must_equal Matrix.zero( @s.free_pp.size, 1 )
  end

  it "6. handles stoichiometric transitions with rate" do
    @s.rate_closures_for_SR.size.must_equal 3
    @s.rate_closures_for_S.size.must_equal 3
    @s.rate_closures.size.must_equal 3
    @s.flux_vector_for_SR.must_equal Matrix.column_vector( [ 0.4, 1.0, 1.5 ] )
    @s.φ_for_SR.must_equal @s.flux_vector
    @s.SR_tt( :φ_for_SR ).must_equal( { T1: 0.4, T2: 1.0, T3: 1.5 } )
    @s.first_order_action_vector_for_SR( 1 )
      .must_equal Matrix.column_vector [ 0.4, 1.0, 1.5 ]
    @s.SR_tt( :first_order_action_for_SR, 1 ).must_equal( T1: 0.4, T2: 1.0, T3: 1.5 )
    @s.Δ_SR( 1 ).must_equal Matrix[[-1.9], [1.0], [1.9]]
    @s.free_pp( :Δ_SR, 1 ).must_equal( { P2: -1.9, P3: 1.0, P4: 1.9 } )
  end

  it "presents sparse stoichiometry vectors for its transitions" do
    @s.sparse_σ( @t1 ).must_equal Matrix.cv( [-1, 0, 1] )
    @s.sparse_stoichiometry_vector( @t1 )
      .must_equal Matrix.cv( [-1, -1, 0, 1, 0] )
  end

  it "presents correspondence matrices free, clamped => all places" do
    @s.F2A.must_equal Matrix[[0, 0, 0], [1, 0, 0], [0, 1, 0],
                                    [0, 0, 1], [0, 0, 0]]
    @s.C2A.must_equal Matrix[[1, 0], [0, 0], [0, 0], [0, 0], [0, 1]]
  end
end
