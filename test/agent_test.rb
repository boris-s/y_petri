#! /usr/bin/ruby
# encoding: utf-8

require 'minitest/autorun'
require_relative '../lib/y_petri'     # tested component itself
# require 'y_petri'
# require 'sy'

describe YPetri::Agent do
  before do
    @m = YPetri::Agent.new
  end

  it "has net basic points" do
    # --- net point related assets ---
    @m.net_point_reset
    @m.net_point_reset @m.world.net( :Top )
    @m.net.must_equal @m.world.Net.instance( :Top )
    # --- simulation point related assets ---
    @m.simulation_point.reset
    @m.simulation.must_equal nil
    @m.simulation_point.key.must_equal nil
    # --- cc point related assets ---
    @m.cc_point.reset
    @m.cc_point.set :Base
    @m.cc.must_equal @m.world.clamp_collection
    @m.cc.wont_equal :Base
    @m.cc_point.key.must_equal :Base
    # --- imc point related assets ---
    @m.imc_point.reset
    @m.imc_point.set :Base
    @m.imc.must_equal @m.world.initial_marking_collection
    @m.imc.wont_equal :Base
    @m.imc_point.key.must_equal :Base
    # --- ssc point related assets ---
    @m.ssc_point.reset
    @m.ssc_point.set :Base
    @m.ssc.must_equal @m.world.simulation_settings_collection
    @m.ssc.wont_equal :Base
    @m.ssc_point.key.must_equal :Base
  end

  it "has basic selections" do
    @m.net_selection.clear
    @m.simulation_selection.clear
    @m.cc_selection.clear
    @m.imc_selection.clear
    @m.ssc_selection.clear
    @m.net_selection.get.must_equal []
    @m.simulation_selection.get.must_equal []
    @m.ssc_selection.get.must_equal []
    @m.cc_selection.get.must_equal []
    @m.imc_selection.get.must_equal []
  end

  it "presents some methods from workspace" do
    [ @m.places, @m.transitions, @m.nets, @m.simulations ].map( &:size )
      .must_equal [ 0, 0, 1, 0 ]
    [ @m.clamp_collections,
      @m.initial_marking_collections,
      @m.simulation_settings_collections ].map( &:size ).must_equal [ 1, 1, 1 ]
    [ @m.clamp_collections,
      @m.initial_marking_collections,
      @m.simulation_settings_collections ]
    .map( &:keys ).must_equal [[:Base]] * 3
    @m.pn.must_equal []
    @m.tn.must_equal []
    @m.nn.must_equal [ :Top ]       # ie. :Top net spanning whole workspace
  end

  describe "slightly more complicated case" do
    before do
      @p = @m.Place ɴ: "P", default_marking: 1
      @q = @m.Place ɴ: "Q", default_marking: 1
      @decay_t = @m.Transition ɴ: "Tp", s: { P: -1 }, rate: 0.1
      @constant_flux_t = @m.Transition ɴ: "Tq", s: { Q: 1 }, rate: -> { 0.02 }
      @m.initial_marking @p => 1.2
      @m.initial_marking @q => 2
      @m.set_step 0.01
      @m.set_sampling 1
      @m.set_time 0..30
    end

    it "works" do
      @m.run!
      @m.simulation.send( :places ).map( &:source )
        .must_equal [ @p, @q ]
      @m.simulation.send( :transitions ).map( &:source )
        .must_equal [ @decay_t, @constant_flux_t ]
      @m.simulation.nTS.must_equal [ :Tp, :Tq ]
      @m.simulation.send( :transition, :Tp ).sparse_stoichiometry_vector
        .must_equal Matrix.column_vector( [-1, 0] )
      @m.simulation.send( :S_transitions )
        .stoichiometry_matrix.column_size.must_equal 2
      @m.simulation.send( :S_transitions )
        .stoichiometry_matrix.row_size.must_equal 2
      @m.simulation.flux_vector.row_size.must_equal 2
      # @m.plot_recording
      rec = @m.simulation.recording
      rec.marking.plot
      rec.flux.plot
      rec.gradient.plot
      rec.delta_timed( Δt: 1 ).plot
      rec.delta_timeless( Δt: 1 ).plot
      @m.plot_marking
      @m.plot_flux
      @m.plot_gradient
      @m.plot_delta( Δt: 1 )
    end
  end
end
