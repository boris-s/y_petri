#! /usr/bin/ruby
# encoding: utf-8

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
    net = @w.Net.send :new
    net.places.must_equal []
    net.transitions.must_equal []
    net.pp.must_equal []
    net.tt.must_equal []
  end

  describe "element access" do
    before do
      @net = @w.Net.send :new
    end

    it "should be able to include places" do
      p = @w.Place.send :new, name: "A", quantum: 0.1, marking: 1.1
      @net.includes_place?( p ).must_equal false
      @net.include_place( p ).must_equal true
      @net.places.must_equal [ p ]
      @net.place( :A ).must_equal p
      @net.Places( [] ).must_equal []
      @net.places( :A ).must_equal [ p ]
    end
  end

  describe "world with 3 places" do
    before do
      @p1 = @w.Place.send :new, name: "A", quantum: 0.1, marking: 1.1
      @p2 = @w.Place.send :new, name: "B", quantum: 0.1, marking: 2.2
      @p3 = @w.Place.send :new, name: "C", quantum: 0.1, marking: 3.3
      @p4 = @w.Place.send :new, name: "X", marking: 0
    end

    describe "net of 3 places and no transitions" do
      before do
        @net = @w.Net.of [ @p1, @p2, @p3 ]
      end

      it "should expose its elements" do
        @net.places.must_equal [ @p1, @p2, @p3 ]
        @net.pn.must_equal [ :A, :B, :C ]
        @net.transitions.must_equal []
      end

      it "should allow only right transitions to be included in it" do
        assert @net.include?( @p1 )
        assert ! @net.include?( @p4 )
        t = @w.Transition.send :new, s: { @p4 => -1 }
        -> { @net.include_transition t }.must_raise RuntimeError
      end

      it "should expose (thus far empty) transition groups" do
        assert_equal [], @net.S_transitions
        assert_equal [], @net.s_transitions
      end

      it "should be able to tell its qualities" do
        assert_equal false, @net.functional?
        assert_equal false, @net.timed?
        assert @net.include?( @p1 )
        assert ! @net.include?( YPetri::Place.send :new )
      end

      it "should know its state (marking owned by the places)" do
        @net.state.must_be_kind_of YPetri::Net::State
        @net.state.must_equal [ @p1, @p2, @p3 ].map( &:marking )
        @net.marking.must_equal [ @p1, @p2, @p3 ].map( &:marking )
        @net.marking.must_be_kind_of Array
      end

      it "should have standard equipment expected of a class" do
        assert @net == @net.dup
        assert @net.inspect.start_with? "#<Net:"
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
          @net.Transitions( [] ).must_equal []
          @net.transitions( :T1 ).must_equal [ @t1 ]
          @net.element( :T1 ).must_equal @t1
          @net.Elements( [] ).must_equal []
          @net.elements( :T1 ).must_equal [ @t1 ]
          @net.elements( :A, :T1 ).must_equal [ @p1, @t1 ]
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

        it "should know right flux, firing, gradient and delta features" do
          @net.firing( [] ).must_equal []
          -> { @net.firing }.must_raise TypeError
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
            @t2 = @w.Transition.send :new, s: { @p2 => -1, @p3 => 1 }
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
            assert_equal true, @net.functional?
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


describe "state, features, record and dataset" do
  before do
    @w = YPetri::World.new
    @net = @w.Net.send :new
    @net << @w.Place.send( :new, ɴ: :A, m!: 2 )
    @net << @w.Place.send( :new, ɴ: :B, m!: 3 )
    @net << @w.Place.send( :new, ɴ: :C, m!: 4 )
    # TS transitions A2B, A_plus
    @net << @w.Transition.send( :new, ɴ: :A2B, s: { A: -1, B: 1 }, rate: 0.01 )
    @net << @w.Transition.send( :new, ɴ: :A_plus, domain: :A, s: { A: 1 }, rate: -> a { a * 0.001 } )
    # tS transitions A2B_s, A_plus_t
    @net << @w.Transition.send( :new, ɴ: :A2B_t, s: { A: -1, B: 1 }, action: proc { 0.42 } )
    @net << @w.Transition.send( :new, ɴ: :A_plus_t, s: { A: 1 }, action: -> { 0.42 } )
    # Ts transition
    @net << @w.Transition.send( :new, ɴ: :C_plus, domain: [:A, :B], codomain: :C,
                                rate: -> a, b { a * 0.001 + b ** 2 * 0.0002 } )
    # ts transition
    @net << @w.Transition.send( :new, ɴ: :C_minus, domain: :C, codomain: :C,
                                action: -> c { - c * 0.5 } )
    # A transition
    @net << @w.Transition.send( :new, ɴ: :C_to_42, codomain: :C,
                                assignment: -> { 42 } )
  end

  describe YPetri::Net::State do
    before do
      @w = YPetri::World.new
      @net = @w.Net.send :new
    end

    it "should be already a param. subclass on @w.Net" do
      @St = @net.State
      @St.net.must_equal @net
      assert @St.Feature < YPetri::Net::State::Feature # is a PS
      -> { @St.Feature( marking: :A ) }.must_raise NameError
    end
  end

  describe YPetri::Net::State::Feature do
    before do
      @sim = @net.simulation step: 1.0
    end
      
    describe YPetri::Net::State::Feature::Marking do
      before do
        @m = @net.State.Feature.Marking( :A )
      end

      it "should have expected attributes" do
        @m.type.must_equal :marking
        @m.place.must_equal @net.place( :A )
      end

      it "should work" do
        @m.extract_from( @sim ).must_equal 2
        @m.must_equal @net.State.Feature.Marking( :A )
      end
    end

    describe YPetri::Net::State::Feature::Flux do
      before do
        @f = @net.State.Feature.Flux( :A2B )
      end

      it "should have expected attributes" do
        @f.type.must_equal :flux
        @f.transition.must_equal @net.transition( :A2B )
      end

      it "should work" do
        @f.extract_from( @sim ).must_equal 0.02
        @f.must_equal @net.State.Feature.Flux( :A2B )
      end
    end

    describe YPetri::Net::State::Feature::Firing do
      before do
        @fT = @net.State.Feature.Firing( :A2B )
        @ft = @net.State.Feature.Firing( :A2B_t )
      end

      it "should have expected attributes" do
        @fT.type.must_equal :firing
        @ft.type.must_equal :firing
        @fT.timed?.must_equal true
        @ft.timed?.must_equal false
        @fT.transition.must_equal @net.transition( :A2B )
        @ft.transition.must_equal @net.transition( :A2B_t )
      end

      it "should work" do
        @ft.extract_from( @sim ).must_equal 0.42
        @fT.extract_from( @sim, Δt: 0.5 ).must_equal 0.01
        @ft.must_equal @net.State.Feature.Firing( :A2B_t )
      end
    end

    describe YPetri::Net::State::Feature::Gradient do
      before do
        @g1 = @net.State.Feature.Gradient( :A, transitions: [:A2B] )
        @g2 = @net.State.Feature.Gradient( :A, transitions: [:A2B, :A_plus] )
        @g3 = @net.State.Feature.Gradient( :A, transitions: :C_plus )
        @g4 = @net.State.Feature.Gradient( :C, transitions: [:C_plus] )
        @g5 = @net.State.Feature.Gradient( :A, transitions: [:A2B, :C_plus] )
        @g6 = @net.State.Feature.Gradient( :C, transitions: [:A2B, :C_plus] )
        @ga = @net.State.Feature.Gradient( :A ) # total gradient
        @gc = @net.State.Feature.Gradient( :C ) # total gradient
      end

      it "should have expected attributes" do
        assert [ @g1, @g2, @g3, @g4, @g5, @g6, @ga, @gc ].map( &:type )
          .must_equal [ :gradient ] * 8
        @g1.place.must_equal @net.place( :A )
        @g1.transitions.must_equal @net.transitions( :A2B )
        @ga.place.must_equal @net.place( :A )
        @ga.tt.names.sort.must_equal [:A2B, :A_plus, :C_plus].sort # all of them
        @gc.tt.names.sort.must_equal [:A2B, :A_plus, :C_plus].sort # all of them
      end

      it "should work" do
        @g1.extract_from( @sim ).must_be_within_epsilon -0.02
        @g2.extract_from( @sim ).must_be_within_epsilon -0.018
        @g3.extract_from( @sim ).must_be_within_epsilon 0
        @g4.extract_from( @sim ).must_be_within_epsilon 0.0038
        @g5.extract_from( @sim ).must_be_within_epsilon -0.02
        @g6.extract_from( @sim ).must_be_within_epsilon 0.0038
        @ga.extract_from( @sim ).must_be_within_epsilon -0.018
        @gc.extract_from( @sim ).must_be_within_epsilon 0.0038
        @g2.must_equal @net.State.Feature.Gradient( :A, transitions: [ :A_plus, :A2B ] )
      end
    end

    describe YPetri::Net::State::Feature::Delta do
      before do
        @d1T = @net.State.Feature.Delta( :A, transitions: [ :A2B ] )
        @dT = @net.State.Feature.Delta( :A, transitions: @net.T_tt )
        @d1t = @net.State.Feature.Delta( :A, transitions: [ :A2B_t ] )
        @d2t = @net.State.Feature.Delta( :A, transitions: :A_plus_t )
        @d3t = @net.State.Feature.Delta( :A, transitions: [ :C_minus ] )
        @dt = @net.State.Feature.Delta( :A, transitions: @net.t_tt )
      end

      it "should have expected attributes" do
        assert [ @d1T, @dT, @d1t, @dt ].all? { |f| f.type == :delta }
        assert [ @d1T, @dT ].all? &:timed?
        assert ! [ @d1t, @d2t, @dt ].any?( &:timed? )
        [ @d1T, @dT, @d1t, @d2t, @d3t, @dt ].map( &:place ).names
          .must_equal [ :A ] * 6
        @d1T.transitions.must_equal @net.tt( :A2B )
        @dT.transitions.must_equal @net.T_tt.sort_by( &:object_id )
        @d1t.transitions.must_equal @net.tt( :A2B_t )
        @d2t.transitions.must_equal @net.tt( :A_plus_t )
        @dt.tt.names.sort.must_equal [ :A2B_t, :A_plus_t, :C_minus ].sort
      end

      it "should work" do
        @d1T.extract_from( @sim, Δt: 1 ).must_be_within_epsilon -0.02
        @d1T.extract_from( @sim, Δt: 10 ).must_be_within_epsilon -0.2
        @dT.extract_from( @sim, Δt: 1 ).must_be_within_epsilon -0.018
        @d1t.extract_from( @sim ).must_be_within_epsilon -0.42
        @d2t.extract_from( @sim ).must_be_within_epsilon 0.42
        @d3t.extract_from( @sim ).must_be_within_epsilon 0
        @dt.extract_from( @sim ).must_be_within_epsilon 0
        @dT.must_equal @net.State.Feature.Delta( :A, transitions: @net.T_tt.reverse )
      end
    end

    describe YPetri::Net::State::Feature::Assignment do
      before do
        @af1 = @net.State.Feature.Assignment( :C, transition: :C_to_42 )
        @af2 = @net.State.Feature.Assignment( :C )
      end

      it "should have the expected attributes" do
        @af1.type.must_equal :assignment
        @af2.type.must_equal :assignment
        @af1.transition.must_equal @net.transition( :C_to_42 )
        @af2.transition.must_equal @net.transition( :C_to_42 )
      end

      it "should work" do
        @af1.extract_from( @sim ).must_equal 42
        @af2.extract_from( @sim ).must_equal 42
        @af1.must_equal @net.State.Feature.Assignment( :C )
      end
    end
  end

  describe YPetri::Net::State::Features do
    before do
      @sim = @net.simulation step: 1.0
      @Ff = @sim.net.State.Features
    end

    describe "#Marking and #marking feature set constructors" do
      before do
        @ff1 = @Ff.Marking [ :A, :B ]
        @ff2 = @Ff.marking :B, :A
        @ff3 = @Ff.marking
      end

      it "should work" do
        @ff1.extract_from( @sim ).must_equal [ 2, 3 ]
        @ff2.extract_from( @sim ).must_equal [ 3, 2 ]
        @ff3.extract_from( @sim ).must_equal [ 2, 3, 4 ]
        @ff1.must_equal @Ff.marking( :A ) + @Ff.marking( :B )
      end
    end

    describe "#Firing and #firing feature set constructors" do
      before do
        @ff1 = @Ff.Firing [ :A2B_t, :A_plus_t ]
        @ff2 = @Ff.firing :A2B_t, :A_plus_t
        @ff3 = @Ff.Firing [ :A2B, :A_plus ]
        @ff4 = @Ff.firing :A2B, :A_plus
        @ff5 = @Ff.firing
      end

      it "should work" do
        @ff1.extract_from( @sim ).must_equal [ 0.42, 0.42 ]
        @ff2.extract_from( @sim ).must_equal [ 0.42, 0.42 ]
        @ff3.extract_from( @sim, Δt: 2 ).must_equal [ 0.04, 0.004 ]
        @ff4.extract_from( @sim, Δt: 1 ).must_equal [ 0.02, 0.002 ]
        @ff5.map( &:transition ).names.sort
          .must_equal [ :A2B, :A_plus, :A2B_t, :A_plus_t ].sort
        @ff5.extract_from( @sim, delta_time: 0.5 )
          .must_equal [ 0.01, 0.001, 0.42, 0.42 ]
        @ff1.must_equal @Ff.firing( :A2B_t ) + @Ff.firing( :A_plus_t )
      end
    end

    describe "#Gradient and #gradient feature set constructors" do
      before do
        @ff0 = @Ff.Gradient [], transitions: []
        @ff1 = @Ff.Gradient [ :A, :B ], transitions: [ :A2B ]
        @ff2 = @Ff.gradient :B, :A, transitions: :A_plus
        @ff3 = @Ff.gradient :C, transitions: [ :A2B, :C_plus ]
      end

      it "should work" do
        @ff0.extract_from( @sim ).must_equal []
        @ff1.extract_from( @sim ).must_equal [ -0.02, 0.02 ]
        @ff2.extract_from( @sim ).must_equal [ 0.0, 0.002 ]
        @ff3.extract_from( @sim )[ 0 ].must_be_within_epsilon 0.0038
        @ff2.must_equal @Ff.gradient( :B, transitions: :A_plus ) +
          @Ff.gradient( :A, transitions: :A_plus )
      end
    end

    describe "#Flux and #flux feature set constructors" do
      before do
        @ff0 = @Ff.Flux []
        @ff1 = @Ff.Flux [ :A2B ]
        @ff2 = @Ff.flux :A2B, :A_plus
      end

      it "should work" do
        @ff0.extract_from( @sim ).must_equal []
        @ff1.extract_from( @sim ).must_equal [ 0.02 ]
        @ff2.extract_from( @sim ).must_equal [ 0.02, 0.002 ]
        @ff2.must_equal @Ff.flux( :A2B ) + @Ff.flux( :A_plus )
      end
    end

    describe "#Delta and #delta feature set constructors" do
      before do
        @ff0 = @Ff.Delta [], transitions: []
        @ff1 = @Ff.Delta [ :A, :B ], transitions: :A2B
        @ff2 = @Ff.delta :A, :B, transitions: [ :A_plus_t, :C_minus ]
        @ff3 = @Ff.delta :A, :B, transitions: :A2B
        @ff4 = @Ff.delta transitions: @net.T_tt
        @ff5 = @Ff.delta_timeless
        @ff6 = @Ff.delta_timed
      end

      it "should work" do
        @ff0.extract_from( @sim ).must_equal []
        @ff1.extract_from( @sim, Δt: 0.1 ).must_equal [ -0.002, 0.002 ]
        @ff2.extract_from( @sim ).must_equal [ 0.42, 0.0 ]
        @ff3.extract_from( @sim, delta_time: 1 ).must_equal [ -0.02, 0.02 ]
        @ff4.map( &:place ).names.sort.must_equal [ :A, :B, :C ].sort
        @ff4.extract_from( @sim, Δt: 0.5 ).map( &[:round, 6] )
          .must_equal [ -0.009, 0.01, 0.0019 ]
        -> { @Ff.delta }.must_raise ArgumentError
        @ff5.extract_from( @sim ).must_equal [ 0.0, 0.42, -2.0 ]
        @ff6.extract_from( @sim, Δt: 0.5 ).map( &[:round, 6] )
          .must_equal [ -0.009, 0.01, 0.0019 ]
        @ff1.must_equal @Ff.delta( :A, transitions: :A2B ) +
          @Ff.delta( :B, transitions: :A2B )
      end
    end

    describe "#Assignment and #assignment feature set constructors" do
      before do
        @ff0 = @Ff.Assignment []
        @ff1 = @Ff.assignment :C
        @ff2 = @Ff.assignment :C, transition: :C_to_42
        @ff3 = @Ff.aa
      end

      it "should work" do
        @ff0.extract_from( @sim ).must_equal []
        @ff1.extract_from( @sim ).must_equal [ 42 ]
        @ff2.extract_from( @sim ).must_equal [ 42 ]
        @ff3.extract_from( @sim ).must_equal [] # ends up empty because
        # techically, place :C with its A transition :C_to_42 does not
        # make sense, as there are also a transitions upstream of :C.
        -> { @Ff.assignment }.must_raise ArgumentError
        @ff1.must_equal @ff2
      end
    end

    describe "#[] constructor" do
      before do
        @ff0 = @Ff[]
        @ff1 = @Ff[ :A, :A2B, :A2B_t ]
        @ff2 = @Ff[ marking: [ :A, :B ],
                    flux: :A2B,
                    gradient: [ :A, transitions: :A2B ] ]
      end

      it "should work" do
        @ff0.extract_from( @sim ).must_equal []
        @ff1.extract_from( @sim ).must_equal [ 2, 0.02, 0.42 ]
        @ff2.extract_from( @sim ).must_equal [ 2, 3, 0.02, -0.02 ]
        -> { @Ff[ :A, marking: [ :B ] ] }.must_raise ArgumentError
        @ff2.must_equal @Ff[ :A, :B, :A2B ] +
          @Ff.gradient( :A, transitions: :A2B )
      end
    end

    describe "feature reduction methods and other miscellanea" do
      before do
        @ff = @Ff[ marking: [ :A, :B ], flux: :A2B,
                    gradient: [ :A, transitions: :A2B ] ]
        @ff2 = @Ff[ :A2B, :A_plus ]
      end

      it "should work" do
        ( @ff + @ff2 ).labels
          .must_equal [ ":A", ":B", "Φ:A2B", "∂:A:A2B", "Φ:A2B", "Φ:A_plus" ]
        @ff.Marking( [ :A ] ).must_equal @Ff[ :A ]
        @ff.marking.must_equal @Ff[ :A, :B ]
        @ff.Firing( [ ] ).must_equal @Ff[]
        @ff.firing.must_equal @Ff[]
        @ff.flux( :A2B ).must_equal @Ff[ :A2B ]
        -> { @ff.Flux( [ :A ] ) }.must_raise NameError
        @ff.gradient( :A, transitions: :A2B )
          .must_equal @Ff.gradient( :A, transitions: :A2B )
        @ff.delta.must_equal @Ff[]
        @ff.assignment.must_equal @Ff[]
      end
    end
  end

  describe YPetri::Net::State::Features::Record do
    before do
      @sim = @net.simulation step: 1.0
      @Ff = @sim.net.State.Features
      @ff = @Ff[ :A, :B, :A2B ] + @Ff.assignment( :C )
      @ff2 = @Ff.marking + @Ff[ :A2B ]
    end

    describe "instance methods" do
      before do
        @tuple = @ff.extract_from( @sim )
        @tuple2 = @ff2.extract_from( @sim )
        @r = @ff.Record.load @tuple
        @r2 = @ff2.Record.load @tuple2
      end

      it "should work" do
        @r.must_equal [ 2, 3, 0.02, 42 ]
        @r.fetch( :A ).must_equal 2
        @r.fetch( :A2B ).must_equal 0.02
        @r.fetch( @Ff[ assignment: :C ].first ).must_equal 42
        @r.dump.class.must_equal Array
        @r.dump.must_equal [ 2, 3, 0.02, 42 ]
        @r.dump( precision: 1 ).must_equal [ 2, 3, 0, 42 ]
        @r2.state.must_equal [ 2, 3, 4 ]
        @r2.reconstruct( marking_clamps: { B: 43 }, step: 0.1, time: 0..100 )
          .must_be_kind_of @net.Simulation
        @r2.Marking( [ :C, :A ] ).must_equal [ 4, 2 ]
        @r2.marking( :B ).must_equal [ 3 ]
        @r2.flux.must_equal [ 0.02 ]
        @r2.firing.must_equal []
        @r2.gradient.must_equal []
        @r2.delta.must_equal []
        @r.features.map( &:type )
          .must_equal [ :marking, :marking, :flux, :assignment ]
        @r.assignment.must_equal [ 42 ]
        u = @ff.Record [ 0, 0, 0 ]
        u.must_equal @ff.Record( [ 0, 0, 0 ] )
        v = @ff.load [ 0, 3, 4 ]
        u.euclidean_distance( v ).must_be_within_epsilon 5
      end
    end
  end

  describe YPetri::Net::State do
    before do
      @sim = @net.simulation step: 1.0
      @S = @net.State
    end

    it "should have certain feature constructors" do
      @S.Features( [ :A, :B, :A2B ] ).must_equal @S.Features[ @S.Feature( :A ),
                                                              @S.Feature( :B ),
                                                              @S.Feature( :A2B ) ]
    end

    describe "instance methods" do
      before do 
        @ff = @S.Features[ :A, :B, :C, :A2B ]
        @r = @ff.load @ff.extract_from( @sim )
        @s = @r.state
      end

      it "should have certain instance methods" do
        @s.marking( :A ).must_equal @r.fetch( :A )
        @s.markings( :A, :B ).must_equal @r.marking( :A, :B )
      end
    end
  end

  describe YPetri::Net::DataSet do
    it "should be constructible" do
      ds = @net.State.Features.Marking( [ :A, :B ] ).DataSet.new( type: :foobar )
      ds.update foo: [ 42, 43 ] # add line 1
      ds.update bar: [ 43, 44 ] # add line 2
      ds.timed?.must_equal false
      ds2 = @net.State.Features.marking.DataSet.new( type: :timed )
      ds2.features.must_equal @net.State.Features.marking( :A, :B, :C )
    end

    describe "timed dataset" do
      before do
        @ds = @net.State.Features.marking( :A, :B ).DataSet.new( type: :timed )
        @ds.update 0.0 => [ 0, 0 ]
        @ds.update 10.0 => [ 1, 0.5 ]
        @ds.update 50.0 => [ 2, 3 ]
        @ds.update 200.0 => [ 2.5, 7 ]
      end

      it "should give a nice plot" do
        @ds.plot
      end

      describe "resampling" do
        before do
          @resampled_ds = @ds.resample sampling: 11
        end

        it "should give a nice plot" do
          @resampled_ds.plot
        end

        it "should be able to reconstruct flux" do
          @resampled_ds.flux.plot
        end
      end
    end
  end
end
