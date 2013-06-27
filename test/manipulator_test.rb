#! /usr/bin/ruby
# -*- coding: utf-8 -*-

require 'minitest/spec'
require 'minitest/autorun'
require_relative '../lib/y_petri'     # tested component itself
# require 'y_petri'
# require 'sy'

describe ::YPetri::Manipulator do
  before do
    @m = ::YPetri::Manipulator.new
  end
  
  it "has net basic points" do
    # --- net point related assets ---
    @m.net_point_reset
    @m.net_point_set @m.workspace.net( :Top )
    @m.net.must_equal @m.workspace.Net::Top
    # --- simulation point related assets ---
    @m.simulation_point.reset
    @m.simulation.must_equal nil
    @m.simulation_point.key.must_equal nil
    # --- cc point related assets ---
    @m.cc_point.reset
    @m.cc_point.set :Base
    @m.cc.must_equal @m.workspace.clamp_collection
    @m.cc.wont_equal :Base
    @m.cc_point.key.must_equal :Base
    # --- imc point related assets ---
    @m.imc_point.reset
    @m.imc_point.set :Base
    @m.imc.must_equal @m.workspace.initial_marking_collection
    @m.imc.wont_equal :Base
    @m.imc_point.key.must_equal :Base
    # --- ssc point related assets ---
    @m.ssc_point.reset
    @m.ssc_point.set :Base
    @m.ssc.must_equal @m.workspace.simulation_settings_collection
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
    @m.pp.must_equal []
    @m.tt.must_equal []
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
      @m.set_time 30
    end
    
    it "works" do
      @m.run!
      @m.simulation.places.must_equal [ @p, @q ]
      @m.simulation.transitions.must_equal [ @decay_t, @constant_flux_t ]
      @m.simulation.SR_tt.must_equal [ :Tp, :Tq ]
      @m.simulation.sparse_stoichiometry_vector( :Tp )
        .must_equal Matrix.column_vector( [-1, 0] )
      @m.simulation.stoichiometry_matrix_for( @m.transitions ).column_size
        .must_equal 2
      @m.simulation.stoichiometry_matrix_for( @m.transitions ).row_size
        .must_equal 2
      @m.simulation.flux_vector.row_size.must_equal 2
      # @m.plot_recording
    end
  end
end