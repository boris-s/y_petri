#! /usr/bin/ruby
# encoding: utf-8

require 'minitest/spec'
require 'minitest/autorun'
require_relative '../lib/y_petri'     # tested component itself
# require 'y_petri'
# require 'sy'
require_relative 'world_mock'

describe YPetri::Net do
  before do
    @w = YPetri::World.new
  end

  it "should initialize" do
    net = @w.Net.new
    net.places.must_equal []
    net.transitions.must_equal []
    net.pp.must_equal []
    net.tt.must_equal []
  end

  describe "element access" do
    before do
      @net = @w.Net.new
    end

    it "should work" do
      p = @w.Place.new name: "A", quantum: 0.1, marking: 1.1
      @net.includes_place?( p ).must_equal false
      @net.include_place p
      @net.places.must_equal [ p ]
      @net.place( :A ).must_equal p
      @net.places( [] ).must_equal []
      @net.places( [:A] ).must_equal [ p ]
    end
  end

  describe "world with 3 places" do
    before do
      @p1 = @w.Place.new name: "A", quantum: 0.1, marking: 1.1
      @p2 = @w.Place.new name: "B", quantum: 0.1, marking: 2.2
      @p3 = @w.Place.new name: "C", quantum: 0.1, marking: 3.3
      @p4 = @w.Place.new name: "X", marking: 0
    end

    describe "net of 3 places and no transitions" do
      before do
        # @p1.m = 1.1
        # @p2.m = 2.2
        # @p3.m = 3.3
        @net = @w.Net.of @p1, @p2, @p3
      end

      it "should expose its elements" do
        assert_equal [@p1, @p2, @p3], @net.places
        assert_equal [:A, :B, :C], @net.pn
        assert_equal [], @net.transitions
      end

      it "should expose transition groups" do
        assert_equal [], @net.S_transitions
        assert_equal [], @net.s_transitions
      end

      it "should tell its qualities" do
        assert_equal true, @net.functional?
        assert_equal false, @net.timed?
        assert @net.include?( @p1 ) && !@net.include?( YPetri::Place.new )
      end

      it "should have 'standard equipment' methods" do
        assert @net == @net.dup
        assert @net.inspect.start_with? "#<Net:"
        assert @net.include?( @p1 )
        assert ! @net.include?( @p_not_included )
        begin
          @net.exclude_place! @p_not_included
          @net.include_transition! YPetri::Transition.new( s: { @p_not_included => -1 } )
          flunk "Attempt to include illegal transition fails to raise"
        rescue; end
      end

      describe "plus 1 stoichio. transition with rate" do
        before do
          @t1 = @w.Transition.avid( ɴ: "T1",
                                    s: { @p1 => 1, @p2 => -1, @p3 => -1 },
                                    rate: 0.01 )
          @net.include_transition @t1
        end

        it "should expose its elements" do
          assert_equal [ @t1 ], @net.transitions
          assert_equal [ :T1 ], @net.tn
          @net.transition( :T1 ).must_equal @t1
          @net.transitions( [] ).must_equal []
          @net.transitions( [ :T1 ] ).must_equal [ @t1 ]
          @net.element( :T1 ).must_equal @t1
          @net.elements( [] ).must_equal []
          @net.elements( [ :T1 ] ).must_equal [ @t1 ]
          @net.elements( [ :A, :T1 ] ).must_equal [ @p1, @t1 ]
        end

        it "should expose transition groups" do
          assert_equal [@t1], @net.S_transitions
          assert_equal [], @net.s_transitions
        end

        it "should tell its qualities" do
          assert_equal true, @net.functional?
          assert_equal true, @net.timed?
          assert @net.include?( @t1 )
        end

        it "should have #place & #transition for safe access to them" do
          @net.send( :place, @p1 ).must_equal @p1
          @net.send( :transition, @t1 ).must_equal @t1
          @net.send( :element, @p1 ).must_equal @p1
        end

        it "has #new_simulation & #new_timed_simulation constructors" do
          @net.must_respond_to :simulation
        end

        it "should have other methods" do
          assert_equal [1.1, 2.2, 3.3], [@p1, @p2, @p3].map( &:marking ).map{ |n| n.round 6 }
          assert_equal 2.2 * 3.3 * 0.01, @t1.rate_closure.call( @p2.marking, @p3.marking )
          assert_equal [ @p2, @p3 ], @t1.domain
          @t1.fire! 1
          assert_equal [1.1726, 2.1274, 3.2274], [@p1, @p2, @p3].map( &:marking ).map{ |n| n.round 6 }
        end

        describe "plus 1 more nameless timeless functionless transition" do
          before do
            @t2 = @w.Transition.new s: { @p2 => -1, @p3 => 1 }
            @net.include_transition @t2
          end

          it "should expose its elements" do
            assert_equal [@t1, @t2], @net.transitions
            assert_equal [:T1, nil], @net.tn
            @net.tap{ |n| n.exclude_transition @t1 }.exclude_transition @t2
            @net.tap{ |n| n.exclude_place @p3 }.pn.must_equal [:A, :B]
          end

          it "should expose transition groups" do
            assert_equal [], @net.ts_transitions
            assert_equal [], @net.nts
            assert_equal [@t2], @net.tS_transitions
            assert_equal [nil], @net.ntS
            assert_equal [@t1], @net.TS_transitions
            assert_equal [:T1], @net.nTS
            assert_equal [], @net.A_transitions
            assert_equal [], @net.nA
            assert_equal [@t1, @t2], @net.S_transitions
            assert_equal [:T1, nil], @net.nS
            assert_equal [], @net.s_transitions
            assert_equal [], @net.ns
            assert_equal [@t1], @net.T_transitions
            assert_equal [:T1], @net.nT
            assert_equal [@t2], @net.t_transitions
            assert_equal [nil], @net.nt
          end

          it "should tell its qualities" do
            assert_equal false, @net.functional?
            assert_equal true, @net.timed?
            @net.exclude_transition @t2
            assert_equal true, @net.functional?
            assert_equal true, @net.timed?
          end
        end
      end
    end
  end
end
