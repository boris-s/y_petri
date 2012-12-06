# -*- coding: utf-8 -*-
 #! /usr/bin/ruby
#coding: utf-8

require 'minitest/spec'
require 'minitest/autorun'
require_relative '../lib/y_petri'     # tested component itself

include Pyper if require 'pyper'

# **************************************************************************
# Test of Place class, part I.
# **************************************************************************
#
describe ::YPetri::Place do
  before do
    # skip "to speed up testing"
    @ç = ::YPetri::Place
    @p = @ç.new default_marking: 3.2, marking: 1.1, quantum: 0.1, name: "p1"
  end

  it "should have constant magic included" do
    assert_respond_to @p, :name
    assert_equal @p.name, "p1"
  end

  it "should have own marking and be able to update it" do
    assert_equal 1.1, @p.marking
    assert_equal 0.1, @p.quantum
    assert_equal "p1", @p.name
    @p.add 1
    assert_equal 2.1, @p.value        # alias for #marking
    @p.subtract 0.5
    assert_equal 1.6, @p.m
    @p.reset_marking
    assert_equal 3.2, @p.marking
  end
  
  it "should respond to the arc getters" do
    # #action_arcs & aliases
    assert_equal [], @p.upstream_arcs
    assert_equal [], @p.upstream_transitions
    assert_equal [], @p.ϝ
    # #test_arcs & aliases
    assert_equal [], @p.downstream_arcs
    assert_equal [], @p.downstream_transitions
    # #arcs & aliases
    assert_equal [], @p.arcs
    assert_equal [], @p.connectivity
    # #precedents & aliases
    assert_equal [], @p.precedents
    assert_equal [], @p.upstream_places
    # #dependents & aliases
    assert_equal [], @p.dependents
    assert_equal [], @p.downstream_places
  end

  it "should respond to register and fire conn. transitions methods" do
    assert_respond_to @p, :fire_upstream!
    assert_respond_to @p, :fire_downstream!
    assert_respond_to @p, :fire_upstream_recursively
    assert_respond_to @p, :fire_downstream_recursively
  end
end

# **************************************************************************
# Test of Transition class, part I.
# **************************************************************************
#
describe ::YPetri::Transition do
  before do
    # skip "to speed up testing"
    @ç, @pç = ::YPetri::Transition, ::YPetri::Place
    @p1 = @pç.new default_marking: 1.0
    @p2 = @pç.new default_marking: 2.0
    @p3 = @pç.new default_marking: 3.0
    @p4 = @pç.new default_marking: 4.0
    @p5 = @pç.new default_marking: 5.0
  end

  describe "1. timeless nonstoichiometric (ts) transitions" do

    # Note that timeless nonstoichiometric transitions require a function
    # block, and thus are always functional

    before do
      @t1 = @ç.new codomain: [ @p1, @p3 ], domain: @p2, action: λ { |a| [ a, a ] }
      # saying that the trans. is timed saves the day here:
      @t2 = @ç.new codomain: [ @p1, @p3 ], action: λ { |t| [ t, t ] }, timed: true
      # Only with domain is 1-ary closure allowed to be timeless:
      @t3 = @ç.new codomain: [ @p1, @p3 ], action: λ { |t| [ t, t ] }, timed: false, domain: [ @p2 ]
      # With nullary action closure, timeless is implied, so this is allowed
      @t4 = @ç.new action: λ { [ 0.5, 0.5 ] }, codomain: [ @p1, @p3 ]
      # ... also for stoichiometric variety
      @t5 = @ç.new action: λ { 0.5 }, codomain: [ @p1, @p3 ], s: [ 1, 1 ]
    end

    it "should have constant magic included" do
      
    end

    it "should raise errors for bad parameters" do
      # omitting the domain should raise ArgumentError about too much ambiguity:
      assert_raises AE do @ç.new codomain: [ @p1, @p3 ], action: λ { |t| [ t, t ] } end
      # saying that the transition is timeless points to a conflict:
      assert_raises AE do @ç.new codomain: [ @p1, @p3 ], action: λ { |t| [ t, t ] }, timeless: true end
    end

    it "should initi and perform" do
      assert_equal [ @p2 ], @t1.domain
      assert_equal [ @p1, @p3 ], @t1.action_arcs
      assert @t1.functional?
      assert @t1.timeless?
      assert @t2.timed?
      assert [@t3, @t4, @t5].all? { |t| t.timeless? }
      assert @t2.rateless?
      # that's enough, now let's flex them:
      @t1.fire!
      assert_equal [3, 5], [ @p1.marking, @p3.marking ]
      @t3.fire!
      assert_equal [5, 7], [ @p1.marking, @p3.marking ]
      @t4.fire!
      assert_equal [5.5, 7.5], [ @p1.marking, @p3.marking ]
      @t5.fire!
      assert_equal [6, 8], [ @p1.marking, @p3.marking ]
      # now t2 for firing requires delta time
      @t2.fire! 1
      assert_equal [7, 9], [ @p1.marking, @p3.marking ]
      @t2.fire! 0.1
      assert_equal [7.1, 9.1], [@p1.marking, @p3.marking ]
      # let's change @p2 marking
      @p2.marking = 0.1
      @t1.fire!
      assert_in_epsilon 7.2, @p1.marking, 1e-9
      assert_in_epsilon 9.2, @p3.marking, 1e-9
      # let's test #domain_marking, #codomain_marking, #zero_action
      assert_equal [ @p1.marking, @p3.marking ], @t1.codomain_marking
      assert_equal [ @p2.marking ], @t1.domain_marking
      assert_equal [ 0, 0 ], @t1.zero_action
    end
  end

  describe "2. timed rateless non-stoichiometric (Tsr) transitions" do
    #LATER: To save time, I omit the full test suite.
  end

  describe "3. timeless stoichiometric (tS) transitions" do
    describe "functionless tS transitions" do

      # For transitions with no function given (ie. functionless), it is
      # required that their stoichiometric vector be given and their action
      # closure is then automatically generated from the stoichio. vector

      before do
        # timeless transition with stoichiometric vector only, as hash
        @t1 = ::YPetri::Transition.new stoichiometry: { @p1 => 1 }
        # timeless transition with stoichiometric vector as array + codomain
        @t2 = ::YPetri::Transition.new stoichiometry: 1, codomain: @p1
        # :stoichiometric_vector is aliased as :sv
        @t3 = ::YPetri::Transition.new s: 1, codomain: @p1
        # :codomain is aliased as :action_arcs
        @t4 = ::YPetri::Transition.new s: 1, action_arcs: @p1
        # dropping of square brackets around size 1 vectors is optional
        @t5 = ::YPetri::Transition.new s: [ 1 ], downstream: [ @p1 ]
        # another alias for :codomain is :downstream_places
        @t6 = ::YPetri::Transition.new s: [ 1 ], downstream_places: [ @p1 ]
        # and now, all of the above transitions...
        @tt = @t1, @t2, @t3, @t4, @t5, @t6
      end

      it "should work" do
        # ...should be the same, having a single action arc:
        assert @tt.all?{ |t| t.action_arcs == [ @p1 ] }
        # timeless:
        assert @tt.all?{ |t| t.timeless? }
        # rateless:
        assert @tt.all?{ |t| t.rateless? }
        assert @tt.all?{ |t| not t.has_rate? }
        # no assignment action
        assert @tt.all?{ |t| not t.assignment_action? }
        # not considered functional
        assert @tt.all?{ |t| t.functionless? }
        assert @tt.all?{ |t| not t.functional? }
        # and having nullary action closure
        assert @tt.all?{ |t| t.action_closure.arity == 0 }
        # the transitions should be able to #fire!
        @t1.fire!
        # the difference is apparent: marking of place @p1 jumped to 2:
        assert_equal 2, @p1.marking
        # but should not #fire (no exclamation mark) unless cocked
        assert !@t1.cocked?
        @t1.fire
        assert_equal 2, @p1.marking
        # cock it
        @t1.cock
        assert @t1.cocked?
        # uncock again, just to test cocking
        @t1.uncock
        assert @t1.uncocked?
        @t1.cock
        assert !@t1.uncocked?
        @t1.fire
        assert_equal 3, @p1.marking
        # enough playing, we'll reset @p1 marking
        @p1.reset_marking
        assert_equal 1, @p1.marking
        # #action
        assert @tt.all?{ |t| t.action == [ 1 ] }
        # #zero_action
        assert @tt.all?{ |t| t.zero_action }
        # #action_after_feasibility_check
        assert @tt.all?{ |t| t.action_after_feasibility_check == [ 1 ] }
        # #domain_marking
        assert @tt.all?{ |t| t.domain_marking == [] }
        # #codomain_marking
        assert @tt.all?{ |t| t.codomain_marking == [ @p1.marking ] }
        # #enabled?
        assert @tt.all?{ |t| t.enabled? == true }
      end
    end

    describe "functional tS transitions" do

      # If function block is supplied to tS transitions, it governs
      # their action based on marking of the domain places.

      before do
        # stoichiometric vector given as hash
        @t1 = @ç.new action_closure: λ { 1 }, s: { @p1 => 1 }
        # instead of :action_closure, just saying :action is enough
        @t2 = @ç.new action: λ { 1 }, s: { @p1 => 1 }
        # stoichiometric vector given as coeff. array + codomain
        @t3 = @ç.new s: 1, codomain: @p1, action: λ { 1 }
        # while saying timed: false and timeless: true should be ok
        @t4 = @ç.new s: { @p1 => 1 }, action: λ { 1 }, timed: false
        @t5 = @ç.new s: { @p1 => 1 }, action: λ { 1 }, timeless: true
        # even both are ok
        @t6 = @ç.new s: { @p1 => 1 }, action: λ { 1 }, timed: false, timeless: true
        @tt = @t1, @t2, @t3, @t4, @t5, @t6
      end

      it "should raise errors for bad parameters" do
        # saying timed: true should raise a complaint:
        assert_raises AE do @ç.new sv: { @p1 => 1 }, action: λ{ 1 }, timed: true end
        # same for saying timeless: false
        assert_raises AE do
          @ç.new sv: { @p1 => 1 }, action: λ{ 1 }, timeless: false end
        # while conflicting values will raise error
        assert_raises AE do
          @ç.new sv: { @p1 => 1 }, action: λ { 1 }, timeless: true, timed: true
        end
      end

      it "should init and perform" do
        assert @tt.all?{ |t| t.action_arcs == [ @p1 ] }
        assert @tt.all?{ |t| t.timeless? }
        assert @tt.all?{ |t| not t.has_rate? }
        assert @tt.all?{ |t| t.rateless? }
        assert @tt.all?{ |t| not t.assignment_action? }
        assert @tt.all?{ |t| not t.functionless? }
        assert @tt.all?{ |t| t.functional? }
        # and having nullary action closure
        assert @tt.all?{ |t| t.action_closure.arity == 0 }
        # the transitions should be able to #fire!
        @t1.fire!
        # no need for more testing here
      end
    end
  end

  describe "4. timed rateless stoichiometric (TSr) transitions" do

    # Rateless stoichiometric transitions have action closure, and they
    # require a function block, and thus are always functional. Their
    # function block must take Δt as its first argument.

    #LATER: To save time, I omit the tests of TSr transitions for now.
  end

  describe "5. nonstoichiometric transitions with rate (sR transitions)" do
    
    # They require a function block with arity equal to their domain, whose
    # output is an array of rates of the size equal to that of codomain.

    #LATER: To save time, I omit the full test suite.
  end

  describe "6. stoichiometric transitions with rate (SR transitions)" do
    before do
      # now this should give standard mass action by magic:
      @t1 = @ç.new s: { @p1 => -1, @p2 => -1, @p4 => 1 }, flux_closure: 0.1
      # while this has custom flux closure
      @t2 = @ç.new s: { @p1 => -1, @p3 => 1 }, flux_closure: λ { |a| a * 0.5 }
      # while this one even has domain specified:
      @t3 = @ç.new s: { @p1 => -1, @p2 => -1, @p4 => 1 }, upstream_arcs: @p3, flux: λ { |a| a * 0.5 }
    end

    it "should init and work" do
      assert_equal true, @t1.has_rate?
      assert_equal [ @p1, @p2 ], @t1.upstream_arcs
      assert_equal [ @p1, @p2, @p4 ], @t1.action_arcs
      assert_equal [ @p1 ], @t2.domain
      assert_equal [ @p1, @p3 ], @t2.action_arcs
      assert_equal [ @p3 ], @t3.domain
      assert_equal [ @p1, @p2, @p4 ], @t3.action_arcs
      # and flex them
      @t1.fire! 1.0
      assert_equal [ 0.8, 1.8, 4.2 ], [ @p1, @p2, @p4 ].map( &:marking )
      @t2.fire! 1.0
      assert_equal [ 0.4, 3.4 ], [ @p1, @p3 ].map( &:marking )
      # the action t3 cannot fire with delta time 1.0
      assert_raises RuntimeError do @t3.fire! 1.0 end
      assert_equal [ 0.4, 1.8, 3.4, 4.2 ], [ @p1, @p2, @p3, @p4 ].map( &:marking )
      # but it can fire with eg. delta time 0.1
      @t3.fire! 0.1
      assert_in_epsilon 0.23, @p1.marking, 1e-15
      assert_in_epsilon 1.63, @p2.marking, 1e-15
      assert_in_epsilon 3.4, @p3.marking, 1e-15
      assert_in_epsilon 4.37, @p4.marking, 1e-15
    end
  end
end


# **************************************************************************
# Test of mutual knowedge of upstream/downstream arcs of places/transitions.
# **************************************************************************
#
describe "upstream and downstream reference mτs of places and transitions" do
  before do
    # skip "to speed up testing"
    @pç = ::YPetri::Place
    @tç = ::YPetri::Transition
    @a = @pç.new( dflt_m: 1.0 )
    @b = @pç.new( dflt_m: 2.0 )
    @c = @pç.new( dflt_m: 3.0 )
  end

  describe "Place" do
    it "should have #register_ustream/downstream_transition methods" do
      @t1 = @tç.new s: {}
      @a.instance_variable_get( :@upstream_arcs ).must_equal []
      @a.instance_variable_get( :@downstream_arcs ).must_equal []
      @a.send :register_upstream_transition, @t1
      @a.instance_variable_get( :@upstream_arcs ).must_equal [ @t1 ]
    end
  end

  describe "upstream and downstream reference methods" do
    before do
      @t1 = @tç.new s: { @a => -1, @b => 1 }, rate: 1
    end

    it "should show on the referencers" do
      @a.upstream_arcs.must_equal [ @t1 ]
      @b.downstream_arcs.must_equal [ ]
      @b.ϝ.must_equal [ @t1 ]
      @t1.upstream_arcs.must_equal [ @a ]
      @t1.action_arcs.must_equal [ @a, @b ]
    end
  end

  describe "assignment action transitions" do
    before do
      @p = @pç.new default_marking: 1.0
      @t = @tç.new codomain: @p, action: λ { 1 }, assignment_action: true
    end

    it "should work" do
      @p.marking = 3
      assert_equal 3, @p.marking
      @t.fire!
      assert_equal 1, @p.marking
    end
  end # context assignment action transiotions
end


# **************************************************************************
# Test of Net class.
# **************************************************************************
#
describe ::YPetri::Net do
  before do
    # skip "to speed up testing"
    @ç = ::YPetri::Net
    @pç, @tç = ::YPetri::Place, ::YPetri::Transition
  end

  describe "net of 3 places and no transitions" do
    before do
      @net = @ç.new
      @p1 = @pç.new name: "A", quantum: 0.1, marking: 1.1
      @p2 = @pç.new name: "B", quantum: 0.1, marking: 2.2
      @p3 = @pç.new name: "C", quantum: 0.1, marking: 3.3
      @p_not_included = @pç.new name: "X", marking: 0
      [ @p1, @p2, @p3 ].each{ |p| @net.include_place! p }
    end

    it "should expose its elements" do
      assert_equal [@p1, @p2, @p3], @net.places
      assert_equal ["A", "B", "C"], @net.pp
      assert_equal [], @net.transitions
    end

    it "should expose transition groups" do
      assert_equal [], @net.transitions_with_rate
      assert_equal [], @net.rateless_transitions
      assert_equal [], @net.transitions_without_rate
      assert_equal [], @net.stoichiometric_transitions
      assert_equal [], @net.nonstoichiometric_transitions
    end

    it "should tell its qualities" do
      assert_equal true, @net.functional?
      assert_equal true, @net.timed?
      assert @net.include?( @p1 ) && !@net.include?( nil )
    end

    it "should 'standard equipment' methods" do
      assert @net == @net.dup
      assert @net.inspect.start_with? "YPetri::Net[ "
      assert @net.to_s.start_with? "Net[ 3"
      begin
        @net.include_transition! @tç.new( s: { @p_not_included => -1 } )
        flunk "Attempt to include illegal transition fails to raise"
      rescue; end
    end

    describe "plus 1 stoichio. transition with rate" do
      before do
        @t1 = @tç.new ɴ: "T1", s: { @p1 => 1, @p2 => -1, @p3 => -1 }, rate: 0.01
        @net.include_transition! @t1
      end

      it "should expose its elements" do
        assert_equal [@t1], @net.transitions
        assert_equal ["T1"], @net.tt
      end

      it "should expose transition groups" do
        assert_equal true, @t1.has_rate?
        assert_equal [@t1], @net.transitions_with_rate
        assert_equal [], @net.rateless_transitions
        assert_equal [@t1], @net.stoichiometric_transitions
        assert_equal [], @net.nonstoichiometric_transitions
      end

      it "should tell its qualities" do
        assert_equal true, @net.functional?
        assert_equal true, @net.timed?
        assert @net.include?( @t1 )
      end

      it "should have #place & #transition for safe access to the said elements" do
        @net.place( @p1 ).must_equal @p1
        @net.transition( @t1 ).must_equal @t1
      end

      it "has #new_simulation & #new_timed_simulation constructors" do
        @net.must_respond_to :new_simulation
        @net.must_respond_to :new_timed_simulation
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
          @net << ( @t2 = @tç.new s: { @p2 => -1, @p3 => 1 } )
        end
        
        it "should expose its elements" do
          assert_equal [@t1, @t2], @net.transitions
          assert_equal ['T1', nil], @net.tt
          @net.tap{ |n| n.exclude_transition! @t1 }.exclude_transition! @t2
          @net.tap{ |n| n.exclude_place! @p3 }.pp.must_equal [?A, ?B]
        end

        it "should expose transition groups" do
          assert_equal [], @net.timeless_nonstoichiometric_transitions
          assert_equal [], @net.timeless_nonstoichiometric_tt
          assert_equal [@t2], @net.timeless_stoichiometric_transitions
          assert_equal [nil], @net.timeless_stoichiometric_tt
          assert_equal [], @net.timed_nonstoichiometric_transitions_without_rate
          assert_equal [], @net.timed_rateless_nonstoichiometric_transitions
          assert_equal [], @net.timed_nonstoichiometric_tt_without_rate
          assert_equal [], @net.timed_rateless_nonstoichiometric_tt
          assert_equal [], @net.timed_nonstoichiometric_transitions_without_rate
          assert_equal [], @net.timed_rateless_nonstoichiometric_transitions
          assert_equal [], @net.timed_nonstoichiometric_tt_without_rate
          assert_equal [], @net.timed_rateless_nonstoichiometric_tt
          assert_equal [], @net.nonstoichiometric_transitions_with_rate
          assert_equal [], @net.nonstoichiometric_tt_with_rate
          assert_equal [@t1], @net.stoichiometric_transitions_with_rate
          assert_equal ['T1'], @net.stoichiometric_tt_with_rate
          assert_equal [], @net.transitions_with_explicit_assignment_action
          assert_equal [], @net.transitions_with_assignment_action
          assert_equal [], @net.assignment_transitions
          assert_equal [], @net.tt_with_explicit_assignment_action
          assert_equal [], @net.tt_with_assignment_action
          assert_equal [], @net.assignment_tt
          assert_equal [@t1, @t2], @net.stoichiometric_transitions
          assert_equal ['T1', nil], @net.stoichiometric_tt
          assert_equal [], @net.nonstoichiometric_transitions
          assert_equal [], @net.nonstoichiometric_tt
          assert_equal [@t1], @net.timed_transitions
          assert_equal ['T1'], @net.timed_tt
          assert_equal [@t2], @net.timeless_transitions
          assert_equal [nil], @net.timeless_tt
          assert_equal [@t1], @net.transitions_with_rate
          assert_equal ['T1'], @net.tt_with_rate
          assert_equal [@t2], @net.rateless_transitions
          assert_equal [nil], @net.rateless_tt
        end

        it "should tell its qualities" do
          assert_equal false, @net.functional?
          assert_equal false, @net.timed?
          @net.exclude_transition! @t2
          assert_equal true, @net.functional?
          assert_equal true, @net.timed?
        end
      end
    end
  end
end


# **************************************************************************
# Test of Simulation class.
# **************************************************************************
#
describe ::YPetri::Simulation do
  before do
    # skip "to make the testing faster"
    ɱ = ::YPetri
    @ç, @pç, @tç, @nç = ɱ::Simulation, ɱ::Place, ɱ::Transition, ɱ::Net
    @p1 = ::YPetri::Place.new( name: "P1", default_marking: 1 )
    @p2 = ::YPetri::Place.new( name: "P2", default_marking: 2 )
    @p3 = ::YPetri::Place.new( name: "P3", default_marking: 3 )
    @p4 = ::YPetri::Place.new( name: "P4", default_marking: 4 )
    @p5 = ::YPetri::Place.new( name: "P5", default_marking: 5 )
    @t1 = ::YPetri::Transition.new( ɴ: "T1",
                                    s: { @p1 => -1, @p2 => -1, @p4 => 1 },
                                    flux_closure: 0.1 )
    @t2 = ::YPetri::Transition.new( ɴ: "T2",
                                    s: { @p1 => -1, @p3 => 1 },
                                    flux_closure: λ { |a| a * 0.5 } )
    @t3 = ::YPetri::Transition.new( ɴ: "T3",
                                    s: { @p1 => -1, @p2 => -1, @p4 => 1 },
                                    domain: @p3, flux: λ { |a| a * 0.5 } )
    @net = ::YPetri::Net.new << @p1 << @p2 << @p3 << @p4 << @p5 <<
                                @t1 << @t2 << @t3
    @s = ::YPetri::Simulation.new net: @net,
                                  place_clamps: { @p1 => 2.0, @p5 => 2.0 },
                                  initial_marking: { @p2 => @p2.default_marking,
                                                     @p3 => @p3.default_marking,
                                                     @p4 => @p4.default_marking }
  end

  it "exposes the net" do
    @s.net.must_equal @net
  end

  it "exposes Petri net places" do
    @s.places.must_equal [ @p1, @p2, @p3, @p4, @p5 ]
    @s.pp.must_equal [ "P1", "P2", "P3", "P4", "P5" ]
    @s.pp_sym.must_equal [ :P1, :P2, :P3, :P4, :P5 ]
    @s.ppß.must_equal @s.pp_sym
    @s.places_( :pp_sym ).must_equal( { @p1 => :P1, @p2 => :P2,
                                        @p3 => :P3, @p4 => :P4, @p5 => :P5 } )
    @s.pp_sym_( :pp ).must_equal( { P1: "P1", P2: "P2", P3: "P3",
                                    P4: "P4", P5: "P5" } )
    @s.ppß_( :pp ).must_equal @s.pp_sym_( :pp )
    @s.pp_( :ppß ).must_equal( { "P1" => :P1, "P2" => :P2, "P3" => :P3,
                                 "P4" => :P4, "P5" => :P5 } )
  end

  it "exposes Petri net transitions" do
    @s.transitions.must_equal [ @t1, @t2, @t3 ]
    @s.tt.must_equal [ "T1", "T2", "T3" ]
    @s.tt_sym.must_equal [:T1, :T2, :T3]
    @s.ttß.must_equal @s.tt_sym
    @s.transitions_( :ttß ).must_equal( { @t1 => :T1, @t2 => :T2, @t3 => :T3 } )
    @s.tt_sym_( :tt ).must_equal( { T1: "T1", T2: "T2", T3: "T3" } )
    @s.tt_sym_( :tt ).must_equal @s.ttß_( :tt )
    @s.tt_( :ttß ).must_equal( { "T1" => :T1, "T2" => :T2, "T3" => :T3 } )
  end
  
  it "exposes place clamps" do
    @s.place_clamps.must_equal( { @p1 => 2, @p5 => 2 } )
    @s.p_clamps.must_equal( { P1: 2, P5: 2 } )
  end

  it "presents free places" do
    @s.free_places.must_equal [ @p2, @p3, @p4 ]
    @s.free_pp.must_equal [ "P2", "P3", "P4" ]
    @s.free_pp_sym.must_equal [ :P2, :P3, :P4 ]
    @s.free_ppß.must_equal @s.free_pp_sym
    @s.free_places_( :free_ppß )
      .must_equal( { @p2 => :P2, @p3 => :P3, @p4 => :P4 } )
    @s.free_pp_( :free_ppß )
      .must_equal( { "P2" => :P2, "P3" => :P3, "P4" => :P4 } )
    @s.free_ppß_( :free_pp ).must_equal( { P2: "P2", P3: "P3", P4: "P4" } )
    @s.free_pp_sym_( :free_pp ).must_equal @s.free_ppß_( :free_pp )
  end

  it "presents clamped places" do
    @s.clamped_places.must_equal [ @p1, @p5 ]
    @s.clamped_pp.must_equal [ "P1", "P5" ]
    @s.clamped_pp_sym.must_equal [ :P1, :P5 ]
    @s.clamped_ppß.must_equal @s.clamped_pp_sym
    @s.clamped_places_( :clamped_ppß ).must_equal( { @p1 => :P1, @p5 => :P5 } )
    @s.clamped_pp_( :clamped_ppß ).must_equal( { "P1" => :P1, "P5" => :P5 } )
    @s.clamped_pp_sym_( :clamped_pp ).must_equal( { P1: "P1", P5: "P5" } )
    @s.clamped_ppß_( :clamped_pp ).must_equal @s.clamped_pp_sym_( :clamped_pp )
  end

  it "exposes initial marking" do
    @s.initial_marking.must_equal( { @p2 => 2, @p3 => 3, @p4 => 4 } )
    @s.im.must_equal( { P2: 2, P3: 3, P4: 4 } )
    @s.initial_marking_array.must_equal [ 2, 3, 4 ]
    @s.initial_marking_vector.must_equal Matrix[[2], [3], [4]]
    @s.initial_marking_vector.must_equal @s.i𝖒
  end

  it "exposes marking (simulation state)" do
    @s.marking_array.must_equal [2, 3, 4] # (we're after reset)
    @s.marking_array_of_free_places.must_equal @s.marking_array
    @s.marking.must_equal( { @p2 => 2, @p3 => 3, @p4 => 4 } )
    @s.m.must_equal( { P2: 2, P3: 3, P4: 4 } )
    @s.m_free.must_equal @s.m
    @s.marking_vector.must_equal Matrix[[2], [3], [4]]
    [ @s.𝖒, @s.marking_vector_of_free_places, @s.𝖒_free ]
      .each &[:must_equal, @s.marking_vector]
  end
  
  it "separately exposes marking of clamped places" do
    @s.marking_array_of_clamped_places.must_equal [ 2, 2 ]
    @s.marking_of_clamped_places.must_equal( { @p1 => 2, @p5 => 2 } )
    @s.m_clamped.must_equal( { P1: 2, P5: 2 } )
    @s.marking_vector_of_clamped_places.must_equal Matrix[[2], [2]]
    @s.𝖒_clamped.must_equal @s.marking_vector_of_clamped_places
  end

  it "exposes marking of all places (with capitalized M)" do
    @s.marking_array_of_all_places.must_equal [ 2, 2, 3, 4, 2 ]
    @s.marking_array!.must_equal @s.marking_array_of_all_places
    @s.marking_of_all_places.must_equal( { @p1 => 2, @p2 => 2, @p3 => 3, @p4 => 4, @p5 => 2 } )
    @s.marking!.must_equal @s.marking_of_all_places
    @s.m_all.must_equal( { P1: 2, P2: 2, P3: 3, P4: 4, P5: 2 } )
    @s.m!.must_equal @s.m_all
    @s.marking_vector_of_all_places.must_equal Matrix[[2], [2], [3], [4], [2]]
    @s.marking_vector!.must_equal @s.marking_vector_of_all_places
    @s.𝖒_all.must_equal @s.marking_vector!
    @s.𝖒!.must_equal @s.marking_vector!
  end
  
  it "has #create_stoichiometry_matrix_for" do
    assert_equal Matrix.empty(3, 0), @s.create_stoichiometry_matrix_for( [] )
    assert_equal Matrix[[-1], [0], [1]], @s.create_stoichiometry_matrix_for( [@t1] )
    x = Matrix[[-1, -1], [0, 0], [1, 1]]
    x.must_equal @s.create_stoichiometry_matrix_for( [@t1, @t3] )
    x.must_equal( @s.create_𝕾_for( [@t1, @t3] ) )
    @s.𝕾_for!( [] ).must_equal Matrix.empty( 5, 0 )
  end

  it "has stoichiometry matrix for 3. timeless stoichiometric transitions" do
    @s.stoichiometry_matrix_for_timeless_stoichiometric_transitions
      .must_equal Matrix.empty( 3, 0 )
    @s.stoichiometry_matrix_for_tS_transitions.must_equal Matrix.empty( 3, 0 )
    @s.𝕾_for_tS_transitions.must_equal Matrix.empty( 3, 0 )
  end

  it "has stoichiometry matrix for 4. timed rateless stoichiometric transitions" do
    @s.stoichiometry_matrix_for_timed_rateless_stoichiometric_transitions
      .must_equal Matrix.empty( 3, 0 )
    @s.stoichiometry_matrix_for_TSr_transitions.must_equal Matrix.empty( 3, 0 )
    @s.𝕾_for_TSr_transitions.must_equal Matrix.empty( 3, 0 )
  end

  it "has stoichiometry matrix for 6. stoichiometric transitions with rate" do
    @s.stoichiometry_matrix_for_stoichiometric_transitions_with_rate
      .must_equal Matrix[[-1,  0, -1], [0, 1, 0], [1, 0, 1]]
    @s.stoichiometry_matrix_for_SR_transitions
      .must_equal Matrix[[-1,  0, -1], [0, 1, 0], [1, 0, 1]]
    @s.𝕾_for_SR_transitions.must_equal @s.stoichiometry_matrix_for_SR_transitions
    @s.𝕾!.must_equal @s.𝕾_for_SR_transitions
  end

  it "presents 1. timeless nonstoichiometric (ts) transitions" do
    assert_equal [], @s.timeless_nonstoichiometric_transitions
    assert_equal [], @s.ts_transitions
    assert_equal( {}, @s.ts_transitions_( :ts_transitions_ ) )
    assert_equal [], @s.timeless_nonstoichiometric_tt
    assert_equal [], @s.ts_tt
    assert_equal( {}, @s.ts_tt_( :ts_tt_ ) )
    assert_equal [], @s.timeless_nonstoichiometric_tt_sym
    assert_equal [], @s.timeless_nonstoichiometric_ttß
    assert_equal [], @s.ts_tt_sym
    assert_equal [], @s.ts_ttß
    assert_equal( {}, @s.ts_ttß_( :ts_ttß ) )
  end

  it "presents 2. timeless stoichiometric (tS) transitions" do
    assert_equal [], @s.timeless_stoichiometric_transitions
    assert_equal [], @s.tS_transitions
    assert_equal( {}, @s.tS_transitions_( :tS_transitions ) )
    assert_equal [], @s.timeless_stoichiometric_tt
    assert_equal [], @s.tS_tt
    assert_equal( {}, @s.tS_tt_( :tS_tt_ ) )
    assert_equal [], @s.timeless_stoichiometric_tt_sym
    assert_equal [], @s.timeless_nonstoichiometric_ttß
    assert_equal [], @s.ts_tt_sym
    assert_equal [], @s.ts_ttß
    assert_equal( {}, @s.ts_ttß_( :ts_ttß ) )
  end

  it "presents 3. timed rateless nonstoichiometric (Tsr) transitions" do
    assert_equal [], @s.timed_nonstoichiometric_transitions_without_rate
    assert_equal [], @s.timed_rateless_nonstoichiometric_transitions
    assert_equal [], @s.Tsr_transitions
    assert_equal( {}, @s.Tsr_transitions_( :Tsr_transitions ) )
    assert_equal [], @s.timed_nonstoichiometric_tt_without_rate
    assert_equal [], @s.timed_rateless_nonstoichiometric_tt
    assert_equal [], @s.Tsr_tt
    assert_equal( {}, @s.Tsr_tt_( :Tsr_tt ) )
    assert_equal [], @s.timed_rateless_nonstoichiometric_tt_sym
    assert_equal [], @s.timed_rateless_nonstoichiometric_ttß
    assert_equal [], @s.Tsr_tt_sym
    assert_equal [], @s.Tsr_ttß
    assert_equal( {}, @s.Tsr_ttß_( :Tsr_ttß ) )
  end

  it "presents 4. timed rateless stoichiometric (TSr) transitions" do
    assert_equal [], @s.timed_stoichiometric_transitions_without_rate
    assert_equal [], @s.timed_rateless_stoichiometric_transitions
    assert_equal [], @s.TSr_transitions
    assert_equal( {}, @s.TSr_transitions_( :TSr_tt ) )
    assert_equal [], @s.timed_stoichiometric_tt_without_rate
    assert_equal [], @s.timed_rateless_stoichiometric_tt
    assert_equal [], @s.TSr_tt
    assert_equal( {}, @s.TSr_tt_( :TSr_tt ) )
    assert_equal [], @s.timed_rateless_stoichiometric_tt_sym
    assert_equal [], @s.timed_rateless_stoichiometric_ttß
    assert_equal [], @s.TSr_tt_sym
    assert_equal [], @s.TSr_ttß
    assert_equal( {}, @s.TSr_ttß_( :TSr_ttß ) )
  end

  it "presents 5. nonstoichiometric transitions with rate" do
    assert_equal [], @s.nonstoichiometric_transitions_with_rate
    assert_equal [], @s.sR_transitions
    assert_equal( {}, @s.sR_transitions_( :sR_transitions ) )
    assert_equal [], @s.nonstoichiometric_tt_with_rate
    assert_equal [], @s.sR_tt
    assert_equal( {}, @s.sR_tt_( :sR_tt ) )
    assert_equal [], @s.sR_tt_sym
    assert_equal [], @s.sR_ttß
    assert_equal( {}, @s.sR_ttß_( :sR_ttß ) )
  end

  it "presents 6. stoichiometric transitions with rate" do
    assert_equal [@t1, @t2, @t3], @s.stoichiometric_transitions_with_rate
    assert_equal @s.stoichiometric_transitions_with_rate, @s.SR_transitions
    assert_equal( { @t1 => :T1, @t2 => :T2, @t3 => :T3 }, @s.SR_transitions_( :SR_ttß ) )
    assert_equal ["T1", "T2", "T3"], @s.stoichiometric_tt_with_rate
    assert_equal @s.stoichiometric_tt_with_rate, @s.SR_tt
    assert_equal [:T1, :T2, :T3], @s.SR_tt_sym
    assert_equal @s.SR_tt_sym, @s.SR_ttß
    assert_equal( { T1: "T1", T2: "T2", T3: "T3" }, @s.SR_ttß_( :SR_tt ) )
  end

  it "presents transitions with explicit assignment action (A transitions)" do
    assert_equal [], @s.transitions_with_explicit_assignment_action
    assert_equal [], @s.assignment_transitions
    assert_equal( {}, @s.assignment_transitions_( :assignment_tt ) )
    assert_equal [], @s.tt_with_explicit_assignment_action
    assert_equal [], @s.assignment_tt
    assert_equal( {}, @s.assignment_tt_( :assignment_ttß ) )
    assert_equal [], @s.assignment_tt_sym
    assert_equal [], @s.assignment_ttß
    assert_equal( {}, @s.assignment_ttß_( :assignment_tt ) )
  end

  it "presents stoichiometric transitions of any kind (S transitions)" do
    assert_equal [@t1, @t2, @t3], @s.stoichiometric_transitions
    assert_equal ["T1", "T2", "T3"], @s.stoichiometric_tt
    assert_equal( { T1: "T1", T2: "T2", T3: "T3" }, @s.S_ttß_( :S_tt ) )
  end

  it "presents nonstoichiometric transitions of any kind (s transitions)" do
    assert_equal [], @s.nonstoichiometric_transitions
    assert_equal [], @s.nonstoichiometric_tt
    assert_equal( {}, @s.s_ttß_( :s_tt ) )
  end

  it "presents transitions with rate (R transitions), of any kind" do
    assert_equal [@t1, @t2, @t3], @s.transitions_with_rate
    assert_equal ["T1", "T2", "T3"], @s.tt_with_rate
    assert_equal( { T1: "T1", T2: "T2", T3: "T3" }, @s.R_ttß_( :R_tt ) )
  end

  it "presents transitions without rate (r transitions), of any kind" do
    assert_equal [], @s.transitions_without_rate
    @s.rateless_transitions.must_equal @s.transitions_without_rate
    assert_equal [], @s.tt_without_rate
    @s.rateless_tt.must_equal @s.tt_without_rate
    assert_equal( {}, @s.r_ttß_( :r_tt ) )
  end

  it "1. handles timeless nonstoichiometric transitions" do
    @s.Δ_closures_for_ts_transitions.must_equal []
    @s.Δ_if_ts_transitions_fire_once
      .must_equal Matrix.zero( @s.free_places.size, 1 )
  end

  it "2. handles timed rateless nonstoichiometric transitions" do
    @s.Δ_closures_for_Tsr_transitions.must_equal []
    @s.Δ_for_Tsr_transitions( 1.0 )
      .must_equal Matrix.zero( @s.free_places.size, 1 )
  end

  it "3. handles timeless stoichiometric transitions" do
    @s.action_closures_for_tS_transitions.must_equal []
    @s.action_vector_for_tS_transitions.must_equal Matrix.column_vector( [] )
    @s.𝖆_for_t_transitions!.must_equal Matrix.column_vector( [] )
    @s.Δ_if_tS_transitions_fire_once
      .must_equal Matrix.zero( @s.free_places.size, 1 )
  end

  it "4. handles timed rateless stoichiometric transitions" do
    @s.action_closures_for_TSr_transitions.must_equal []
    @s.action_closures_for_Tr_transitions!.must_equal []
    @s.action_vector_for_TSr_transitions( 1.0 )
      .must_equal Matrix.column_vector( [] )
    @s.action_vector_for_Tr_transitions!( 1.0 )
      .must_equal Matrix.column_vector( [] )
    @s.Δ_for_TSr_transitions( 1.0 )
      .must_equal Matrix.zero( @s.free_places.size, 1 )
  end

  it "5. handles nonstoichiometric transitions with rate" do
    assert_equal [], @s.rate_closures_for_sR_transitions
    assert_equal [], @s.rate_closures_for_s_transitions!
    @s.state_differential_for_sR_transitions
      .must_equal Matrix.zero( @s.free_places.size, 1 )
    @s.Δ_Euler_for_sR_transitions( 1.0 )
      .must_equal Matrix.zero( @s.free_places.size, 1 )
  end

  it "6. handles stoichiometric transitions with rate" do
    @s.rate_closures_for_SR_transitions.size.must_equal 3
    @s.rate_closures_for_S_transitions!.size.must_equal 3
    @s.rate_closures!.size.must_equal 3
    @s.flux_vector_for_stoichiometric_transitions_with_rate
      .must_equal Matrix.column_vector( [ 0.4, 1.0, 1.5 ] )
    @s.flux_vector_for_SR_transitions
      .must_equal Matrix.column_vector( [ 0.4, 1.0, 1.5 ] )
    @s.𝖋_for_stoichiometric_transitions_with_rate
      .must_equal Matrix.column_vector( [ 0.4, 1.0, 1.5 ] )
    @s.𝖋_for_SR_transitions
      .must_equal Matrix.column_vector( [ 0.4, 1.0, 1.5 ] )
    @s.flux_vector!.must_equal Matrix.column_vector( [ 0.4, 1.0, 1.5 ] )
    @s.𝖋!.must_equal Matrix.column_vector( [ 0.4, 1.0, 1.5 ] )
    @s.flux_for_SR_ttß.must_equal( { T1: 0.4, T2: 1.0, T3: 1.5 } )
    @s.f!.must_equal( { T1: 0.4, T2: 1.0, T3: 1.5 } )
    @s.Euler_action_vector_for_SR_transitions( 1 )
      .must_equal Matrix.column_vector [ 0.4, 1.0, 1.5 ]
    @s.Euler_action_for_SR_tt_sym( 1 ).must_equal( T1: 0.4, T2: 1.0, T3: 1.5 )
    @s.Δ_Euler_for_SR_transitions( 1 ).must_equal Matrix[[-1.9], [1.0], [1.9]]
    @s.Δ_Euler_for_SR_ttß( 1 ).must_equal( { P2: -1.9, P3: 1.0, P4: 1.9 } )
    @s.Δ_euler_for_SR_ttß( 1 ).must_equal( { P2: -1.9, P3: 1.0, P4: 1.9 } )
  end

  it "presents sparse stoichiometry vectors for its transitions" do
    @s.sparse_stoichiometry_vector( @t1 ).must_equal Matrix.cv( [-1, 0, 1] )
    @s.sparse_𝖘( @t1 ).must_equal Matrix.cv( [-1, 0, 1] )
    @s.sparse_stoichiometry_vector!( @t1 )
      .must_equal Matrix.cv( [-1, -1, 0, 1, 0] )
    @s.sparse_𝖘!( @t1 ).must_equal Matrix.cv( [-1, -1, 0, 1, 0] )
  end

  it "presents correspondence matrices free, clamped => all places" do
    @s.f2p_matrix.must_equal Matrix[[0, 0, 0], [1, 0, 0], [0, 1, 0],
                                    [0, 0, 1], [0, 0, 0]]
    @s.c2p_matrix.must_equal Matrix[[1, 0], [0, 0], [0, 0], [0, 0], [0, 1]]
  end
end


# **************************************************************************
# Test of TimedSimulation class.
# **************************************************************************
#
describe ::YPetri::TimedSimulation do  
  before do
    # skip "to speed up testing"
    @a = ::YPetri::Place.new default_marking: 1.0
    @b = ::YPetri::Place.new default_marking: 2.0
    @c = ::YPetri::Place.new default_marking: 3.0
  end

  describe "timed assembly a + b >> c" do
    before do
      @t1 = ::YPetri::Transition.new s: { @a => -1, @b => -1, @c => 1 }, rate: 0.1
      @net = ::YPetri::Net.new << @a << @b << @c << @t1
      @im_collection = [@a, @b, @c].τBmχHτ &:default_marking
    end

    describe "simulation with step size 1" do
      before do
        @sim = ::YPetri::TimedSimulation.new net: @net,
                                             initial_marking: @im_collection,
                                             step: 1,
                                             sampling: 10,
                                             target_time: 100
      end

      it "should #step! with expected results" do
        m = @sim.step!.marking_array!
        assert_in_delta 0.8, m[ 0 ], 1e-9
        assert_in_delta 1.8, m[ 1 ], 1e-9
        assert_in_delta 3.2, m[ 2 ], 1e-9
      end

      it "should behave" do
        assert_in_delta 0, ( Matrix.column_vector( [-0.02, -0.02, 0.02] ) -
                             @sim.Δ_Euler_free( 0.1 ) ).column( 0 ).norm, 1e-9
        @sim.step! 0.1
        assert_in_delta 0, ( Matrix.column_vector( [0.98, 1.98, 3.02] ) -
                             @sim.marking_vector ).column( 0 ).norm, 1e-9

      end
    end

    describe "simulation with step size 0.1" do
      before do
        @sim = ::YPetri::TimedSimulation.new net: @net,
                                             initial_marking: @im_collection,
                                             step: 0.1,
                                             sampling: 10,
                                             target_time: 100
      end

      it "should behave" do
        m = @sim.step!.marking_array!
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

  describe "timed 'isomerization' with flux given as λ" do
    before do
      @t2 = ::YPetri::Transition.new s: { @a => -1, @c => 1 },
                                     rate_closure: λ { |a| a * 0.5 }
      @net = ::YPetri::Net.new << @a << @b << @c << @t2
    end

    describe "behavior of #step" do
      before do
        @sim = ::YPetri::TimedSimulation.new net: @net,
                 initial_marking: [ @a, @b, @c ].τBᴍHτ( &:default_marking ),
                 step: 1,
                 sampling: 10
      end

      it "should have expected stoichiometry matrix" do
        @sim.stoichiometry_matrix!.must_equal Matrix[ [-1, 0, 1] ].t
        m = @sim.step!.marking_array!
        m[ 0 ].must_be_within_epsilon( 0.5, 1e-6 )
        m[ 1 ].must_equal 2
        m[ 2 ].must_be_within_delta( 3.5, 1e-9 )
      end
    end
  end

  describe "timed controlled isomerization" do
    before do
      @t3 = ::YPetri::Transition.new s: { @a => -1, @c => 1 },
                                     domain: @b,
                                     rate: λ { |a| a * 0.5 }
      @net = ::YPetri::Net.new << @a << @b << @c << @t3
      @sim = ::YPetri::TimedSimulation.new net: @net,
               initial_marking: { @a => 1, @b => 0.6, @c => 3 },
               step: 1,
               sampling: 10,
               target_time: 2
    end

    it "should exhibit correct behavior of #step" do
      @sim.marking_array!.must_equal [1.0, 0.6, 3.0]
      @t3.stoichiometric?.must_equal true
      @t3.timed?.must_equal true
      @t3.has_rate?.must_equal true
      @sim.gradient!.must_equal Matrix.cv [-0.3, 0.0, 0.3]
      @sim.Δ_Euler_all.must_equal Matrix.cv [-0.3, 0.0, 0.3]
      @sim.step!
      @sim.marking_vector!.must_equal Matrix.cv [0.7, 0.6, 3.3]
      @sim.euler_step!
      @sim.run!
      @sim.marking_vector!.map( &[:round, 5] )
        .must_equal Matrix.cv [0.4, 0.6, 3.6]
    end
  end
end


# **************************************************************************
# Test of Workspace class.
# **************************************************************************
#
describe ::YPetri::Workspace do
  before do
    # skip "to speed up testing"
    @w = ::YPetri::Workspace.new
    @pp, @tt = [], []
    @pp << @w.new_place( default_marking: 1.0, name: "AA" )
    @pp << @w.new_place( default_marking: 2.0, name: "BB" )
    @pp << ::YPetri::Place.new( ɴ: "CC", default_marking: 3.0 )
    @w.include_place! @pp[-1]
    @tt << @w.new_transition( s: { @pp[0] => -1, @pp[1] => -1, @pp[2] => 1 },
                              rate: 0.1,
                              ɴ: "AA_&_BB_assembly" )
    @tt << ::YPetri::Transition.new( ɴ: "AA_appearing",
                                     codomain: @pp[0],
                                     rate: λ{ 0.1 },
                                     stoichiometry: 1 )
    @w.include_transition! @tt[-1]
    @f_name = "test_output.csv"
    @w.set_imc @pp.τBᴍHτ( &:default_marking )
    @w.set_ssc step: 0.1, sampling: 10, target_time: 50
    @w.set_cc( {} )
    @sim = @w.new_timed_simulation
    File.delete @f_name rescue nil
  end

  it "should present places, transitions, nets, simulations" do
    assert_kind_of ::YPetri::Net, @w.net
    assert_equal @pp[0], @w.place( "AA" )
    assert_equal "AA", @w.p( @pp[0] )
    assert_equal @tt[0], @w.transition( "AA_&_BB_assembly" )
    assert_equal "AA_appearing", @w.t( @tt[1] )
    assert_equal @pp, @w.places
    assert_equal @tt, @w.transitions
    assert_equal 1, @w.nets.size
    assert_equal 1, @w.simulations.size
    assert_equal 0, @w.cc.size
    assert_equal 3, @w.imc.size
    assert [0.1, 10, 50].each { |e| @w.ssc.include? e }
    assert_equal @sim, @w.simulation
    assert_equal [:base], @w.ccc
    assert_equal [:base], @w.imcc
    assert_equal [:base], @w.sscc
    assert_equal ["AA", "BB", "CC"], @w.pp
    assert_equal ["AA_&_BB_assembly", "AA_appearing"], @w.tt
    assert_equal [nil], @w.nn
  end

  it "should simulate" do
    assert_kind_of( ::YPetri::Simulation, @w.simulation )
    assert_equal 2, @w.simulation.SR_transitions.size
    @tt[0].domain.must_equal [ @pp[0], @pp[1] ]
    @tt[1].domain.must_equal []
    assert_equal [0.2, 0.1], @w.simulation.𝖋!.column_to_a
    @w.simulation.step!
    @w.simulation.run!
    rec_string = @w.simulation.recording_csv_string
    expected_recording_string =
      "0.0,1.0,2.0,3.0\n" +
      "10.0,0.86102,0.86102,4.13898\n" +
      "20.0,1.29984,0.29984,4.70016\n"
    assert rec_string.start_with?( expected_recording_string )
  end
end

# **************************************************************************
# Test of Manipulator class.
# **************************************************************************
#
describe ::YPetri::Manipulator do
  before do
    # skip "for now"
    @m = ::YPetri::Manipulator.new
  end
  
  it "has net basic points" do
    # --- net point related assets ---
    @m.net_point_reset
    @m.net_point_to @m.workspace.net
    @m.net.must_equal @m.workspace.net
    @m.net_point_position.must_equal 0
    # --- simulation point related assets ---
    @m.simulation_point_reset
    @m.simulation_point_to nil
    @m.simulation.must_equal nil
    @m.simulation_point_position.must_equal nil
    # --- cc point related assets ---
    @m.cc_point_reset
    @m.cc_point_to :base
    @m.cc.must_equal @m.workspace.clamp_collection
    @m.cc.wont_equal :base
    @m.cc_point_position.must_equal :base
    # --- imc point related assets ---
    @m.imc_point_reset
    @m.imc_point_to :base
    @m.imc.must_equal @m.workspace.initial_marking_collection
    @m.imc.wont_equal :base
    @m.imc_point_position.must_equal :base
    # --- ssc point related assets ---
    @m.ssc_point_reset
    @m.ssc_point_to :base
    @m.ssc.must_equal @m.workspace.simulation_settings_collection
    @m.ssc.wont_equal :base
    @m.ssc_point_position.must_equal :base
  end

  it "has basic selections" do
    @m.net_selection_clear
    @m.simulation_selection_clear
    @m.cc_selection_clear
    @m.imc_selection_clear
    @m.ssc_selection_clear
    @m.net_selection.must_equal []
    @m.simulation_selection.must_equal []
    @m.ssc_selection.must_equal []
    @m.cc_selection.must_equal []
    @m.imc_selection.must_equal []
    [ :net, :simulation, :cc, :imc, :ssc ].each { |sym1|
      [ :select!, :select, :unselect ].each { |sym2|
        @m.must_respond_to "#{sym1}_#{sym2}"
      }
    }
  end

  it "presents some methods from workspace" do
    [ @m.places, @m.transitions, @m.nets, @m.simulations ].map( &:size )
      .must_equal [ 0, 0, 1, 0 ]
    [ @m.clamp_collections,
      @m.initial_marking_collections,
      @m.simulation_settings_collections ].map( &:size ).must_equal [ 1, 1, 1 ]
    [ @m.ccc, @m.imcc, @m.sscc ].must_equal [[:base]] * 3
    @m.pp.must_equal []
    @m.tt.must_equal []
    @m.nn.must_equal [ nil ]         # ie. one nameless net
  end
  
  describe "slightly more complicated case" do
    before do
      @p = @m.place ɴ: "P", default_marking: 1
      @q = @m.place ɴ: "Q", default_marking: 1
      @m.transition ɴ: "Tp", s: { P: -1 }, rate: 0.1
      @m.transition ɴ: "Tq", s: { Q: 1 }, rate: λ{ 0.02 }
      @m.clamp @p, 1.2
      @m.initial_marking @q, 2
      @m.set_step 0.01
      @m.set_sampling 1
      @m.set_time 30
    end
    
    it "works" do
      @m.run!
      @m.plot_recording
      sleep 3
    end
  end
end


# **************************************************************************
# Test of YPetri class itself.
# **************************************************************************
#
describe ::YPetri do
  before do
    # skip "to speed up testing"
  end

  it "should have basic classes" do
    [ :Place, :Transition, :Net,
      :Simulation, :TimedSimulation,
      :Workspace, :Manipulator ].each { |ß|
      assert_kind_of Module, ::YPetri.const_get( ß ) }
  end

  describe "'typesafe access' methods Place, Transition, Net" do
    before do
      @a = ::YPetri::Place.new name: "Abc", marking: 7
      @b = ::YPetri::Place.new name: "Bcd", marking: 8
      @t = ::YPetri::Transition.new name: "Tuv", s: { @a => -1, @b => 1 }
      @net = ::YPetri::Net.new( name: "XXX_Net" ) << @a << @b << @t
    end

    it "should work" do
      ::YPetri.Net( @net ).must_equal @net
      ::YPetri.Net( "XXX_Net" ).must_equal @net
      ::YPetri.Net( :XXX_Net ).must_equal @net
      ( ::YPetri.Net( "不知火" ) rescue :raised ).must_equal :raised
      ::YPetri.Place( @a ).must_equal @a
      ::YPetri.Place( :Abc ).must_equal @a
      ::YPetri.Transition( @t ).must_equal @t
      ::YPetri.Transition( :Tuv ).must_equal @t
    end
  end
end


# **************************************************************************
# ACCEPTANCE TESTS
# **************************************************************************

# describe "Token game" do
#   before do
#     @m = YPetri::Manipulator.new
#     @m.place name: "A"
#     @m.place name: "B"
#     @m.place name: "C", marking: 7.77
#     @m.transition name: "A2B", stoichiometry: { A: -1, B: 1 }
#     @m.transition name: "C_decay", stoichiometry: { C: -1 }, rate: 0.05
#   end

#   it "should work" do
#     @m.p( :A ).marking = 2
#     @m.p( :B ).marking = 5
#     @m.places.map( &:name ).must_equal ["A", "B", "C"]
#     @m.places.map( &:marking ).must_equal [2, 5, 7.77]
#     @m.t( :A2B ).connectivity.must_equal [ @m.p( :A ), @m.p( :B ) ]
#     @m.t( :A2B ).fire!
#     @m.places.map( &:marking ).must_equal [1, 6, 7.77]
#     @m.t( :A2B ).fire!
#     @m.p( :A ).marking.must_equal 0
#     @m.p( :B ).marking.must_equal 7
#     2.times do @m.t( :C_decay ).fire! 1 end
#     @m.t( :C_decay ).fire! 0.1
#     200.times do @m.t( :C_decay ).fire! 1 end
#     assert_in_delta @m.p( :C ).marking, 0.00024, 0.00001
#   end
# end

# describe "Basic use of TimedSimulation" do
#   before do
#     @m = YPetri::Manipulator.new
#     @m.place( name: "A", default_marking: 0.5 )
#     @m.place( name: "B", default_marking: 0.5 )
#     @m.transition( name: "A_pump",
#                    stoichiometry: { A: -1 },
#                    rate: proc { 0.005 } )
#     @m.transition( name: "B_decay",
#                    stoichiometry: { B: -1 },
#                    rate: 0.05 )
#   end

#   it "should work" do
#     @m.net.must_be_kind_of ::YPetri::Net
#     @m.run!
#     @m.simulation.must_be_kind_of ::YPetri::TimedSimulation
#     @m.plot_recording
#     sleep 4
#   end
# end

# describe "Simplified dTTP pathway used for demo with Dr. Chang" do
#   before do
#     @m = YPetri::Manipulator.new
#     Cytoplasm_volume_in_litres = 5.0e-11
#     NA = 6.022e23
#     Pieces_per_micromolar = NA / 1_000_000 * Cytoplasm_volume_in_litres
#     @m.set_step 60
#     @m.set_sampling 300
#     @m.set_target_time 60 * 60 * 2
#     AMP = @m.place( name: :AMP, m!: 8695.0 )
#     ADP = @m.place( name: :ADP, m!: 6521.0 )
#     ATP = @m.place( name: :ATP, m!: 3152.0 )
#     Deoxycytidine = @m.place( name: :Deoxycytidine, m!: 0.5 )
#     DeoxyCTP = @m.place( name: :DeoxyCTP, m!: 1.0 )
#     DeoxyGMP = @m.place( name: :DeoxyGMP, m!: 1.0 )
#     UMP_UDP_pool = @m.place( name: :UMP_UDP_pool, m!: 2737.0 )
#     DeoxyUMP_DeoxyUDP_pool = @m.place( name: :DeoxyUMP_DeoxyUDP_pool, m!: 0.0 )
#     DeoxyTMP = @m.place( name: :DeoxyTMP, m!: 3.3 )
#     DeoxyTDP_DeoxyTTP_pool = @m.place( name: :DeoxyTDP_DeoxyTTP_pool, m!: 5.0 )
#     Thymidine = @m.place( name: :Thymidine, m!: 0.5 )
#     TK1 = @m.place( name: :TK1, m!: 100_000 )
#     TYMS = @m.place( name: :TYMS, m!: 100_000 )
#     RNR = @m.place( name: :RNR, m!: 100_000 )
#     TMPK = @m.place( name: :TMPK, m!: 100_000 )
#     TK1_kDa = 24.8
#     TYMS_kDa = 66.0
#     RNR_kDa = 140.0
#     TMPK_kDa = 50.0
#     TK1_a = 5.40
#     TYMS_a = 3.80
#     RNR_a = 1.00
#     TMPK_a = 0.83
#     @m.clamp AMP: 8695.0, ADP: 6521.0, ATP: 3152.0
#     @m.clamp Deoxycytidine: 0.5, DeoxyCTP: 1.0, DeoxyGMP: 1.0
#     @m.clamp Thymidine: 0.5
#     @m.clamp UMP_UDP_pool: 2737.0
#     # Functions
#     Vmax_per_minute_per_enzyme_molecule =
#       lambda { |enzyme_specific_activity_in_micromol_per_minute_per_mg,
#                 enzyme_molecular_mass_in_kDa|
#                   enzyme_specific_activity_in_micromol_per_minute_per_mg *
#                     enzyme_molecular_mass_in_kDa }
#     Vmax_per_minute =
#       lambda { |specific_activity, kDa, enzyme_molecules_per_cell|
#                Vmax_per_minute_per_enzyme_molecule.( specific_activity, kDa ) *
#                  enzyme_molecules_per_cell }
#     Vmax_per_second =
#       lambda { |specific_activity, kDa, enzyme_molecules_per_cell|
#                Vmax_per_minute.( specific_activity,
#                                  kDa,
#                                  enzyme_molecules_per_cell ) / 60 }
#     Km_reduced =
#       lambda { |km, ki_hash={}|
#                ki_hash.map { |concentration, ci_Ki|
#                              concentration / ci_Ki
#                            }.reduce( 1, :+ ) * km }
#     Occupancy =
#       lambda { |concentration, reactant_Km, compet_inh_w_Ki_hash={}|
#                concentration / ( concentration +
#                                  Km_reduced.( reactant_Km,
#                                               compet_inh_w_Ki_hash ) ) }
#     MM_with_inh_micromolars_per_second =
#       lambda { |reactant_concentration,
#                 enzyme_specific_activity,
#                 enzyme_mass_in_kDa,
#                 enzyme_molecules_per_cell,
#                 reactant_Km,
#                 competitive_inh_w_Ki_hash={}|
#                 Vmax_per_second.( enzyme_specific_activity,
#                                   enzyme_mass_in_kDa,
#                                   enzyme_molecules_per_cell ) *
#                   Occupancy.( reactant_concentration,
#                               reactant_Km,
#                               competitive_inh_w_Ki_hash ) }
#     MMi = MM_with_inh_micromolars_per_second
#     TK1_Thymidine_Km = 5.0
#     TYMS_DeoxyUMP_Km = 2.0
#     RNR_UDP_Km = 1.0
#     DNA_creation_speed = 3_000_000_000 / ( 12 * 3600 )
#     TMPK_DeoxyTMP_Km = 12.0

#     # transitions
#     @m.transition name: :TK1_Thymidine_DeoxyTMP,
#                   domain: [ Thymidine, TK1, DeoxyTDP_DeoxyTTP_pool, DeoxyCTP, Deoxycytidine, AMP, ADP, ATP ],
#                   stoichiometry: { Thymidine: -1, DeoxyTMP: 1 },
#                   rate: proc { |rc, e, pool1, ci2, ci3, master1, master2, master3|
#                                ci1 = pool1 * master3 / ( master2 + master3 )
#                                MMi.( rc, TK1_a, TK1_kDa, e, TK1_Thymidine_Km,
#                                      ci1 => 13.5, ci2 => 0.8, ci3 => 40.0 ) }
#     @m.transition name: :TYMS_DeoxyUMP_DeoxyTMP,
#                   domain: [ DeoxyUMP_DeoxyUDP_pool, TYMS, AMP, ADP, ATP ],
#                   stoichiometry: { DeoxyUMP_DeoxyUDP_pool: -1, DeoxyTMP: 1 },
#                   rate: proc { |pool, e, master1, master2, master3|
#                           rc = pool * master2 / ( master1 + master2 )
#                           MMi.( rc, TYMS_a, TYMS_kDa, e, TYMS_DeoxyUMP_Km ) }
#     @m.transition name: :RNR_UDP_DeoxyUDP,
#                   domain: [ UMP_UDP_pool, RNR, DeoxyUMP_DeoxyUDP_pool, AMP, ADP, ATP ],
#                   stoichiometry: { UMP_UDP_pool: -1, DeoxyUMP_DeoxyUDP_pool: 1 },
#                   rate: proc { |pool, e, master1, master2, master3|
#                                rc = pool * master2 / ( master1 + master2 )
#                                MMi.( rc, RNR_a, RNR_kDa, e, RNR_UDP_Km ) }
#     @m.transition name: :DNA_polymerase_consumption_of_DeoxyTTP,
#                   stoichiometry: { DeoxyTDP_DeoxyTTP_pool: -1 },
#                   rate: proc { DNA_creation_speed / 4 }
#     @m.transition name: :TMPK_DeoxyTMP_DeoxyTDP,
#                   domain: [ DeoxyTMP, TMPK, ADP,
#                             DeoxyTDP_DeoxyTTP_pool,
#                             DeoxyGMP, AMP, ATP ],
#                   stoichiometry: { DeoxyTMP: -1, TMPK: 0, DeoxyTDP_DeoxyTTP_pool: 1 },
#                   rate: proc { |rc, e, ci1, pool, ci4, master1, master3|
#                                master2 = ci1
#                                ci2 = pool * master2 / ( master2 + master3 )
#                                ci3 = pool * master3 / ( master2 + master3 )
#                                MMi.( rc, TMPK_a, TMPK_kDa, e, TMPK_DeoxyTMP_Km,
#                                      ci1 => 250.0, ci2 => 30.0, ci3 => 750, ci4 => 117 ) }
#   end

#   it "should work" do
#     @m.run!
#     @m.plot_recording
#     sleep 10
#   end
# end
