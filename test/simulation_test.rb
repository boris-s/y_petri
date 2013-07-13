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
    @s.places.must_equal( [] )
    @s.transitions.must_equal( [] )
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
    end

    describe "transition representation aspects" do
      before do
        @ts = @T.nw "T_ts", domain: :B, codomain: :A, action: -> { 1 }
        @tS = @T.nw "T_tS", s: { B: -1, A: 1 }, action: proc { 1 }
        @Ts = @T.nw "T_Ts", domain: :B, codomain: :A, rate: -> { 1 }
        @TS = @T.nw "T_TS", s: { B: -1, A: 1 }, rate: proc { 1 }
      end

      it "should be what intended" do
        @ts.type.must_equal :ts
        @ts.domain.must_equal [@q]
        @ts.codomain.must_equal [@p]
        @tS.type.must_equal :tS
        @tS.domain.must_equal [@q] # inferred
        @tS.codomain.must_equal [@q, @p]
        @Ts.type.must_equal :Ts
        @Ts.domain.must_equal [@q]
        @Ts.codomain.must_equal [@p]
        @TS.type.must_equal :TS
        @TS.domain.must_equal [@q] # inferred
        @TS.codomain.must_equal [@q, @p]
      end

      describe "behavior with single ts transition" do
        before do
          @net = @N.of @p, @q, @ts
        end

        describe "no clamps" do
          before do 
            @sim = @S.new( net: @net )
          end

          it "should behave" do
            @sim.timed?.must_equal false
            @sim.recording.must_equal( { 0 => [1, 2]} )
            @sim.method.must_equal :pseudo_euler
          end
        end

        describe "with clamps" do
          before do
            @sim = @S.new( net: @net, marking_clamps: { B: 43 } )
          end

          it "should behave" do
            
          end
        end
      end
      
      describe "behavior with single tS transition" do
        before do
          @net = @N.of @p, @q, @tS
        end

        describe "no clamps" do
          before do
            @sim = @S.new( net: @net )
          end

          it "should behave" do
            
          end
        end

        describe "with clamps" do
          before do
            @sim = @S.new( net: @net, marking_clamps: { B: 43 } )
          end

          it "should behave" do
            
          end
        end
      end
    end
  end
end
