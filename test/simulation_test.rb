#! /usr/bin/ruby
# encoding: utf-8

require 'minitest/spec'
require 'minitest/autorun'
require_relative '../lib/y_petri'     # tested component itself
# require 'y_petri'
# require 'sy'
require_relative 'workspace_mock'

describe YPetri::Simulation do
  before do
    @P, @T, @N, @S = *WORKSPACE_MOCK.(), YPetri::Simulation
  end

  it "should allow for creation of an empty simulation" do
    @n = @N.new
    @s = @S.new( net: @n )
    @s.places.must_equal []
    @s.places( *[] ).must_equal []
    @s.transitions.must_equal( [] )
    @s.transitions( *[] ).must_equal []
    @s.m_vector.must_equal Matrix.column_vector( [] )
    @n << @P.new( marking: 1 )
    @n.places.size.must_equal( 1 )
    @s.places.must_equal [] # simulation must not change when net is changed
  end

  describe "simulation setup" do
    before do
      @p, @q = @P.nw( :A, default_marking: 1 ), @P.nw( :B, default_marking: 2 )
      @n = @N.of @p, @q
    end

    it "should allow to set up a simplistic simulation instance" do
      @S.new( net: @n ) # no clamps
      @S.new( net: @n, marking_clamps: { @q => 42 } ) # one clamp
      @S.new net: @n, initial_marking: { @p => 42, @q => 43 }
      @S.new net: @n, marking_clamps: { @p => 42 }, initial_marking: { @q => 43 }
      @S.new net: @n, initial_marking: { A: 42 }
    end

    it "should fail with malformed arguments" do
      -> { @S.new net: @n, use_default_marking: false }.must_raise TypeError
      -> { @S.new net: @n, initial_marking: { Foo: 1 } }.must_raise TypeError
    end

    describe "place representation aspects" do
      before do
        @s = @S.new( net: @n,
                     initial_marking: { A: 42 },
                     marking_clamps: { B: 43 } )
      end

      it "should have elements/access" do
        @s.place( :A ).must_be_kind_of YPetri::Simulation::PlaceRepresentation
        @s.place( :B ).must_be_kind_of YPetri::Simulation::PlaceRepresentation
        @s.net.places.names.must_equal [:A, :B]
        @s.pn.must_equal [:A, :B]
        @s.places.free.size.must_equal 1
        @s.free_places.names.must_equal [:A]
        @s.places.clamped.size.must_equal 1
        @s.clamped_places.names.must_equal [:B]
        @s.places( [:A] ).map( &:source ).must_equal [@p]
        @s.transitions( [] ).must_equal []
        @s.places( [:A] ).map( &:source ).must_equal [@p]
        @s.places( [] ).must_equal []
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
        @ts = @T.nw "T_ts", codomain: :A, action: -> { 1 }
        @tS = @T.nw "T_tS", s: { B: -1, A: 1 }, action: proc { 1 }
        @Ts = @T.nw "T_Ts", codomain: :A, rate: -> { 1 }
        @TS = @T.nw "T_TS", s: { B: -1, A: 1 }, rate: proc { 1 }
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
          @net = @N.of @p, @q, @ts
        end

        describe "no clamps" do
          before do 
            @sim = @S.new( net: @net )
          end

          it "should behave" do
            @sim.transitions.size.must_equal 1
            @ts.codomain.names.must_equal [:A]
            @sim.transitions.ts.first.codomain.names.must_equal [:A]
            @ts.domain.names.must_equal []
            @sim.transitions.ts.first.domain.names.must_equal []
            @sim.timed?.must_equal false
            @sim.m.must_equal [1, 2]
            @sim.pm.must_equal( { A: 1, B: 2 } )
            @sim.recording.must_equal( { 0 => [1, 2]} )
            @sim.method.must_equal :pseudo_euler
            @sim.core.must_be_kind_of YPetri::Simulation::Method
            @sim.transitions.ts.first.domain.must_equal []
            @sim.transitions.ts.first.domain_access_code.must_equal ''
            λ = @sim.transitions.ts.first.delta_closure
            λ.arity.must_equal 0
            λ.call.must_equal 1
            cc = @sim.transitions.ts.delta_closures
            cc.map( &:call ).must_equal [1]
            cl = @sim.transitions.ts.delta_closure
            cl.call.must_equal Matrix[ [1], [0] ]
            @sim.step!
            @sim.pm.must_equal( { A: 2, B: 2 } ) # marking of A goes up by 1
            @sim.recording.must_equal( { 0 => [1, 2], 1 => [2, 2] } )
          end
        end

        describe "with clamps" do
          before do
            @sim = @S.new( net: @net, marking_clamps: { B: 42 } )
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
          @net = @N.of @p, @q, @tS
        end

        describe "no clamps" do
          before do
            @sim = @S.new( net: @net )
          end

          it "should behave" do
            @sim.recording.must_equal( { 0 => [1, 2] } )
            @sim.step!
            @sim.recording.must_equal( { 0 => [1, 2], 1 => [2, 1] } )
          end
        end

        describe "with clamps" do
          before do
            @sim = @S.new( net: @net, marking_clamps: { B: 43 } )
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
          @net = @N.of @p, @q, @Ts
        end

        describe "no clamps" do
          before do
            @sim = @S.new( net: @net, sampling_period: 1 )
          end

          it "should behave" do
            @sim.timed?.must_equal true
            @sim.method.must_equal :pseudo_euler
            @sim.transitions.Ts.size.must_equal 1
            @sim.transitions.Ts.first.gradient_closure.call.must_equal 1
            @sim.transitions.Ts.first.codomain.names.must_equal [:A]
            @sim.recording.must_equal( { 0.0 => [1, 2] } )
            @sim.step! 1
            @sim.recording.must_equal( { 0.0 => [1, 2], 1.0 => [2, 2] } )
          end
        end

        describe "with clamps" do
          before do
            @sim = @S.new( net: @net, sampling_period: 1, marking_clamps: { B: 43 } )
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
          @net = @N.of @p, @q, @TS
        end

        describe "no clamps" do
          before do
            @sim = @S.new( net: @net, sampling_period: 1 )
          end

          it "should behave" do
            @sim.recording.must_equal( { 0.0 => [1, 2] } )
            @sim.step! 1
            @sim.recording.must_equal( { 0.0 => [1, 2], 1.0 => [2, 1] } )
          end
        end

        describe "with clamps" do
          before do
            @sim = @S.new( net: @net, sampling_period: 1, marking_clamps: { B: 43 } )
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
