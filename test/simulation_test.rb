#! /usr/bin/ruby
# encoding: utf-8

gem 'minitest', '=4.7.4'
require 'minitest/autorun'
require_relative '../lib/y_petri'     # tested component itself
# require 'y_petri'
# require 'sy'

describe YPetri::Simulation do
  before do
    @w = YPetri::World.new
  end

  it "should allow for creation of an empty simulation" do
    net = @w.Net.send :new
    sim = net.simulation
    sim.pp.must_equal []
    sim.pp( *[] ).must_equal []
    sim.tt.must_equal( [] )
    sim.tt( *[] ).must_equal []
  end

  describe "simulation setup" do
    before do
      @p = @w.Place.send :new, name: :A, default_marking: 1
      @q = @w.Place.send :new, name: :B, default_marking: 2
      @net = @w.Net.of @p, @q
    end

    it "should allow to set up a simplistic simulation instance" do
      @net.simulation
      @net.simulation marking_clamps: { @q => 42 } # one clamp
      @net.simulation initial_marking: { @p => 42, @q => 43 }
      @net.simulation marking_clamps: { @p => 42 }, initial_marking: { @q => 43 }
      @net.simulation initial_marking: { A: 42 }
    end

    it "should fail with malformed arguments" do
      -> { @net.simulation use_default_marking: false }.must_raise TypeError
      -> { @net.simulation initial_marking: { Foo: 1 } }.must_raise NameError
    end

    describe "place representation aspects" do
      before do
        @s = YPetri::Simulation.new( net: @net,
                                     initial_marking: { A: 42 },
                                     marking_clamps: { B: 43 } )
      end

      it "should have elements/access" do
        @s.send( :place, :A )
            .must_be_kind_of YPetri::Simulation::PlaceRepresentation
        @s.send( :place, :B )
          .must_be_kind_of YPetri::Simulation::PlaceRepresentation
        @s.net.places.names.must_equal [:A, :B]
        @s.pn.must_equal [:A, :B]
        @s.send( :places ).free.size.must_equal 1
        @s.send( :free_places ).names.must_equal [:A]
        @s.send( :places ).clamped.size.must_equal 1
        @s.send( :clamped_places ).names.must_equal [:B]
        @s.send( :places, [:A] ).map( &:source ).must_equal [@p]
        @s.send( :transitions, [] ).must_equal []
        @s.send( :places, [:A] ).map( &:source ).must_equal [@p]
        @s.send( :places, [] ).must_equal []
      end

      describe "marking vector representation" do
        it "should work" do
          @s.instance_variable_get( :@m_vector ).must_equal @s.m_vector
          @s.m_vector.must_be_kind_of YPetri::Simulation::MarkingVector
          @s.m_vector.size.must_equal 2
          @s.m_vector.to_a.must_equal [42, 43]
          @s.m.must_equal [42, 43]
          @s.marking.must_equal [42]
          @s.marking_clamps.keys_to_names.must_equal( { B: 43 } )
        end
      end
    end # describe simulation step

    describe "transition representation aspects" do
      before do
        @ts = @w.Transition.send :new, name: "T_ts", codomain: :A, action: -> { 1 }
        @tS = @w.Transition.send :new, name: "T_tS", s: { B: -1, A: 1 }, action: proc { 1 }
        @Ts = @w.Transition.send :new, name: "T_Ts", codomain: :A, rate: -> { 1 }
        @TS = @w.Transition.send :new, name: "T_TS", s: { B: -1, A: 1 }, rate: proc { 1 }
      end

      it "should be what intended" do
        @ts.type.must_equal :ts
        @ts.domain.must_equal []
        @ts.codomain.must_equal [@p]
        @tS.type.must_equal :tS
        @tS.domain.must_equal [@q] # inferred
        @tS.codomain.must_equal [@q, @p]
        @Ts.type.must_equal :Ts
        @Ts.domain.must_equal []
        @Ts.codomain.must_equal [@p]
        @TS.type.must_equal :TS
        @TS.domain.must_equal [@q] # inferred
        @TS.codomain.must_equal [@q, @p]
      end

      describe "ts transition" do
        before do
          @net = @w.Net.of @p, @q, @ts
        end

        describe "no clamps" do
          before do 
            @sim = @net.simulation net: @net
          end

          it "should behave" do
            @sim.tt.size.must_equal 1
            @ts.codomain.names.must_equal [:A]
            @sim.ts_tt.first.codomain.names.must_equal [:A]
            @ts.domain.names.must_equal []
            @sim.ts_tt.first.domain.names.must_equal []
            @sim.timed?.must_equal false
            @sim.m.must_equal [1, 2]
            @sim.pm.must_equal( { A: 1, B: 2 } )
            @sim.recording.must_equal( { 0 => [1, 2]} )
            @sim.simulation_method.must_equal :pseudo_euler
            @sim.core.must_be_kind_of YPetri::Core
            @sim.ts_tt.first.domain.must_equal []
            @sim.send( :ts_transitions ).first.domain_access_code.must_equal ''
            λ = @sim.send( :transitions ).ts.first.delta_closure
            λ.arity.must_equal 0
            λ.call.must_equal 1
            cc = @sim.send( :transitions ).ts.delta_closures
            cc.map( &:call ).must_equal [1]
            cl = @sim.send( :transitions ).ts.delta_closure
            cl.call.must_equal Matrix[ [1], [0] ]
            @sim.step!
            @sim.pm.must_equal( { A: 2, B: 2 } ) # marking of A goes up by 1
            @sim.recording.must_equal( { 0 => [1, 2], 1 => [2, 2] } )
          end
        end

        describe "with clamps" do
          before do
            @sim = @net.simulation marking_clamps: { B: 42 }
          end

          it "should behave" do
            @sim.recording.must_equal( { 0 => [1] } )
            @sim.step!
            @sim.recording.must_equal( { 0 => [1], 1 => [2] } )
          end
        end
      end # ts transition

      describe "tS transition" do
        before do
          @net = @w.Net.of @p, @q, @tS
        end

        describe "no clamps" do
          before do
            @sim = @net.simulation net: @net
          end

          it "should behave" do
            @sim.recording.must_equal( { 0 => [1, 2] } )
            @sim.step!
            @sim.recording.must_equal( { 0 => [1, 2], 1 => [2, 1] } )
          end
        end

        describe "with clamps" do
          before do
            @sim = @net.simulation marking_clamps: { B: 43 }
          end

          it "should behave" do
            @sim.recording.must_equal( { 0 => [1] } )
            3.times do @sim.step! end
            @sim.recording.must_equal( { 0 => [1], 1 => [2], 2 => [3], 3 => [4] } )
          end
        end
      end # tS transition

      describe "Ts transition" do
        before do
          @net = @w.Net.of @p, @q, @Ts
        end

        describe "no clamps" do
          before do
            @sim = @net.simulation sampling: 1
          end

          it "should behave" do
            @sim.timed?.must_equal true
            @sim.simulation_method.must_equal :pseudo_euler
            @sim.Ts_tt.size.must_equal 1
            @sim.send( :transitions ).Ts.first.gradient_closure.call.must_equal 1
            @sim.Ts_tt.first.codomain.names.must_equal [:A]
            @sim.recording.must_equal( { 0.0 => [1, 2] } )
            @sim.step! 1
            @sim.recording.must_equal( { 0.0 => [1, 2], 1.0 => [2, 2] } )
          end
        end

        describe "with clamps" do
          before do
            @sim = @net.simulation sampling: 1, marking_clamps: { B: 43 }
          end

          it "should behave" do
            @sim.recording.must_equal( { 0.0 => [1] } )
            3.times do @sim.step! 1 end
            @sim.recording.must_equal( { 0.0 => [1], 1.0 => [2], 2.0 => [3], 3.0 => [4] } )
          end
        end
      end # Ts transition

      describe "TS transition" do
        before do
          @net = @w.Net.of @p, @q, @TS
        end

        describe "no clamps" do
          before do
            @sim = @net.simulation sampling: 1
          end

          it "should behave" do
            @sim.recording.must_be_kind_of YPetri::Net::DataSet
            @sim.recording
              .must_equal @net.State.marking.new_dataset.update( 0.0 => [1, 2] )
            @sim.recording.must_equal( { 0.0 => [1, 2] } )
            @sim.step! 1
            @sim.recording.must_equal( { 0.0 => [1, 2], 1.0 => [2, 1] } )
          end
        end

        describe "with clamps" do
          before do
            @sim = @net.simulation sampling: 1, marking_clamps: { B: 43 }
          end

          it "should behave" do
            @sim.recording.must_equal( { 0.0 => [1] } )
            3.times do @sim.step! end
            @sim.recording.must_equal( { 0.0 => [1], 1.0 => [2], 2.0 => [3], 3.0 => [4] } )
          end
        end
      end # TS transition
    end # transition representation aspects
  end
end

describe "timeless simulation" do
  before do
    self.class.class_exec { include YPetri }
    U = Place m!: 2.5
    V = Place m!: 2.5
    Uplus = Transition codomain: :U do 1 end # s transition
    U2V = Transition s: { U: -1, V: 1 }      # S transition
    set_ssc :Timeless, YPetri::Simulation::DEFAULT_SETTINGS.call
    new_simulation ssc: :Timeless
    5.times do simulation.step! end
  end

  it "should behave" do
    s = simulation
    assert ! s.timed?
    s.core.must_be_kind_of YPetri::Core::Timeless::PseudoEuler
    ds = s.recording
    ds.size.must_equal 6
    ds.events.must_equal [0, 1, 2, 3, 4, 5]
    ds.interpolate( 1 )
      .must_equal [2.5, 3.5]
    ds.interpolate( 2 )
      .must_equal [2.5, 4.5]
    -> { ds.interpolate( 1.5 ) }.must_raise TypeError
    ds.reconstruct( event: 2 )
      .pm.must_equal( { U: 2.5, V: 4.5 } )
    ds.marking.slice( 2..4 ).series
      .must_equal [[2.5, 2.5, 2.5], [4.5, 5.5, 6.5]]
    ds.marking.slice( 2..4 )
      .must_equal( { 2 => [2.5, 4.5],
                     3 => [2.5, 5.5],
                     4 => [2.5, 6.5] } )
    ds.firing.slice( 1..2 ).series
      .must_equal [[1, 1]]
    ds.series( firing: [:U2V] )
      .must_equal [ [ 1, 1, 1, 1, 1, 1 ] ]
    ds.delta( [:U], transitions: [:Uplus] ).series
      .must_equal [ [ 1.0, 1.0, 1.0, 1.0, 1.0, 1.0 ] ]
    tmp = ds.reduce_features( marking: [:U], firing: [:U2V] )
    tmp.features
      .must_equal( ds.net.State.features marking: [:U], firing: [:U2V] )
    tmp.must_equal( { 0 => [2.5, 1], 1 => [2.5, 1], 2 => [2.5, 1],
                      3 => [2.5, 1], 4 => [2.5, 1], 5 => [2.5, 1] } )
  end
end

describe "timed simulation" do
  before do
    self.class.class_exec { include YPetri }
    A = Place m!: 0.5
    B = Place m!: 0.5
    A_pump = T s: { A: -1 } do 0.005 end
    B_decay = Transition s: { B: -1 }, rate: 0.05
    run!
  end

  it "should behave" do
    places.map( &:marking ).must_equal [0.5, 0.5] # marking unaffected
    simulation.tap do |s|
      s.settings.must_equal( { method: :pseudo_euler, guarded: false,
                               step: 0.1, sampling: 5, time: 0..60 } ) 
      assert s.recording.to_csv.start_with?( "0.0,0.5,0.5\n" +
                                             "5.0,0.475,0.38916\n" +
                                             "10.0,0.45,0.30289\n" + 
                                             "15.0,0.425,0.23574\n" +
                                             "20.0,0.4,0.18348\n" +
                                             "25.0,0.375,0.1428\n" )
      assert s.recording.to_csv.end_with?( "60.0,0.2,0.02471" )
      s.recording.events.must_equal [ 0.0, 5.0, 10.0, 15.0, 20.0,
                                      25.0, 30.0, 35.0, 40.0, 45.0,
                                      50.0, 55.0, 60.0 ]
      s.recording.values_at( 5, 10 )
        .must_equal [ [0.475, 0.38916], [0.45, 0.30289] ]
      s.recording.slice( 2..12 )
        .must_equal( { 5.0 => [0.475, 0.38916], 10.0=>[0.45, 0.30289] } )
      s.recording.net
        .must_equal net
      s.recording.features
        .must_equal net.State.marking( [:A, :B] )
      net.State.Features.State
        .must_equal net.State
      s.recording.State
        .must_equal net.State
      s.recording.series( marking: [:A] )
        .must_equal [ [ 0.5, 0.475, 0.45, 0.425, 0.4, 0.375, 0.35, 0.325,
                        0.3, 0.275, 0.25, 0.225, 0.2 ] ]
      s.recording.firing.series
        .must_equal []
      s.recording.firing
        .must_equal( [*0..12].map { |n| n * 5.0 } >> [[]] * 13 )
      s.recording
        .delta( [:A], transitions: [:A_pump], delta_time: 0.1 )
        .series
        .must_equal [ [ -0.0005 ] * 13 ]
      plot_state
      sleep 5
    end
  end
end
