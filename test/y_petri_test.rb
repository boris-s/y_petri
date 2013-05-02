#! /usr/bin/ruby
#encoding: utf-8

require 'minitest/spec'
require 'minitest/autorun'
require_relative '../lib/y_petri'     # tested component itself
# require 'y_petri'

# require 'sy'

include Pyper if require 'pyper'

# **************************************************************************
# Test of Place class, part I.
# **************************************************************************
#
describe ::YPetri::Place do
  before do
    # skip "to speed up testing"
    @pç = pç = Class.new ::YPetri::Place
    @p = pç.new! default_marking: 3.2,
                 marking: 1.1,
                 quantum: 0.1,
                 name: "P1"
  end

  describe "place behavior" do
    before do
      @p.m = 1.1
    end

    it "should have constant magic included" do
      assert_respond_to @p, :name
      assert_equal @p.name, :P1
    end

    it "should have own marking and be able to update it" do
      assert_equal 1.1, @p.marking
      assert_equal 0.1, @p.quantum
      assert_equal :P1, @p.name
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
      # #arcs & aliasesnn
      assert_equal [], @p.arcs
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
end

# **************************************************************************
# Test of Transition class, part I.
# **************************************************************************
#
describe ::YPetri::Transition do
  before do
    # skip "to speed up testing"
    @ç = ç = Class.new ::YPetri::Transition
    @pç = pç = Class.new ::YPetri::Place
    [ ç, pç ].each { |ç|
      ç.class_exec {
        define_method :Place do pç end
        define_method :Transition do ç end
        private :Place, :Transition
      }
    }
    @p1 = pç.new default_marking: 1.0
    @p2 = pç.new default_marking: 2.0
    @p3 = pç.new default_marking: 3.0
    @p4 = pç.new default_marking: 4.0
    @p5 = pç.new default_marking: 5.0
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

    it "should raise errors for bad parameters" do
      # omitting the domain should raise ArgumentError about too much ambiguity:
      assert_raises AErr do @ç.new codomain: [ @p1, @p3 ], action: λ { |t| [ t, t ] } end
      # saying that the transition is timeless points to a conflict:
      assert_raises AErr do @ç.new codomain: [ @p1, @p3 ], action: λ { |t| [ t, t ] }, timeless: true end
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
        @ftS1 = @ç.new stoichiometry: { @p1 => 1 }
        # timeless transition with stoichiometric vector as array + codomain
        @ftS2 = @ç.new stoichiometry: 1, codomain: @p1
        # :stoichiometric_vector is aliased as :sv
        @ftS3 = @ç.new s: 1, codomain: @p1
        # :codomain is aliased as :action_arcs
        @ftS4 = @ç.new s: 1, action_arcs: @p1
        # dropping of square brackets around size 1 vectors is optional
        @ftS5 = @ç.new s: [ 1 ], downstream: [ @p1 ]
        # another alias for :codomain is :downstream_places
        @ftS6 = @ç.new s: [ 1 ], downstream_places: [ @p1 ]
        # and now, all of the above transitions...
        @tt = @ftS1, @ftS2, @ftS3, @ftS4, @ftS5, @ftS6
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
        @ftS1.fire!
        # the difference is apparent: marking of place @p1 jumped to 2:
        assert_equal 2, @p1.marking
        # but should not #fire (no exclamation mark) unless cocked
        assert !@ftS1.cocked?
        @ftS1.fire
        assert_equal 2, @p1.marking
        # cock it
        @ftS1.cock
        assert @ftS1.cocked?
        # uncock again, just to test cocking
        @ftS1.uncock
        assert @ftS1.uncocked?
        @ftS1.cock
        assert !@ftS1.uncocked?
        @ftS1.fire
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
        @FtS1 = @ç.new action_closure: λ { 1 }, s: { @p1 => 1 }
        # instead of :action_closure, just saying :action is enough
        @FtS2 = @ç.new action: λ { 1 }, s: { @p1 => 1 }
        # stoichiometric vector given as coeff. array + codomain
        @FtS3 = @ç.new s: 1, codomain: @p1, action: λ { 1 }
        # while saying timed: false and timeless: true should be ok
        @FtS4 = @ç.new s: { @p1 => 1 }, action: λ { 1 }, timed: false
        @FtS5 = @ç.new s: { @p1 => 1 }, action: λ { 1 }, timeless: true
        # even both are ok
        @FtS6 = @ç.new s: { @p1 => 1 }, action: λ { 1 }, timed: false, timeless: true
        @tt = @FtS1, @FtS2, @FtS3, @FtS4, @FtS5, @FtS6
      end

      it "should raise errors for bad parameters" do
        # saying timed: true should raise a complaint:
        assert_raises AErr do @ç.new sv: { @p1 => 1 }, action: λ{ 1 }, timed: true end
        # same for saying timeless: false
        assert_raises AErr do
          @ç.new sv: { @p1 => 1 }, action: λ{ 1 }, timeless: false end
        # while conflicting values will raise error
        assert_raises AErr do
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
        @FtS1.fire!
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
      @SR1 = @ç.new s: { @p1 => -1, @p2 => -1, @p4 => 1 }, flux: 0.1
      # while this has custom flux closure
      @SR2 = @ç.new s: { @p1 => -1, @p3 => 1 }, flux: λ { |a| a * 0.5 }
      # while this one even has domain specified:
      @SR3 = @ç.new s: { @p1 => -1, @p2 => -1, @p4 => 1 }, upstream_arcs: @p3, flux: λ { |a| a * 0.5 }
    end

    it "should init and work" do
      assert_equal true, @SR1.has_rate?
      assert_equal [ @p1, @p2 ], @SR1.upstream_arcs
      assert_equal [ @p1, @p2, @p4 ], @SR1.action_arcs
      assert_equal [ @p1 ], @SR2.domain
      assert_equal [ @p1, @p3 ], @SR2.action_arcs
      assert_equal [ @p3 ], @SR3.domain
      assert_equal [ @p1, @p2, @p4 ], @SR3.action_arcs
      # and flex them
      @SR1.fire! 1.0
      assert_equal [ 0.8, 1.8, 4.2 ], [ @p1, @p2, @p4 ].map( &:marking )
      @SR2.fire! 1.0
      assert_equal [ 0.4, 3.4 ], [ @p1, @p3 ].map( &:marking )
      # the action t3 cannot fire with delta time 1.0
      assert_raises RuntimeError do @SR3.fire! 1.0 end
      assert_equal [ 0.4, 1.8, 3.4, 4.2 ], [ @p1, @p2, @p3, @p4 ].map( &:marking )
      # but it can fire with eg. delta time 0.1
      @SR3.fire! 0.1
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
    @tç = tç = Class.new ::YPetri::Transition
    @pç = pç = Class.new ::YPetri::Place
    [ tç, pç ].each { |ç|
      ç.class_exec {
        define_method :Place do pç end
        define_method :Transition do tç end
        private :Place, :Transition
      }
    }
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
      assert @t.assignment_action?
      assert_equal @t.domain, []
      assert_equal 0, @t.action_closure.arity
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
    @tç = tç = Class.new ::YPetri::Transition
    @pç = pç = Class.new ::YPetri::Place
    @nç = nç = Class.new ::YPetri::Net
    [ tç, pç, nç ].each { |ç|
      ç.class_exec {
        define_method :Place do pç end
        define_method :Transition do tç end
        define_method :Net do nç end
        private :Place, :Transition, :Net
      }
    }
    @p1 = pç.new ɴ: "A", quantum: 0.1, marking: 1.1
    @p2 = pç.new ɴ: "B", quantum: 0.1, marking: 2.2
    @p3 = pç.new ɴ: "C", quantum: 0.1, marking: 3.3
    @net = nç.new
    [ @p1, @p2, @p3 ].each { |p| @net.include_place! p }
    @p_not_included = pç.new ɴ: "X", m: 0
  end

  describe "net of 3 places and no transitions" do
    before do
      @p1.m = 1.1
      @p2.m = 2.2
      @p3.m = 3.3
    end

    it "should expose its elements" do
      assert_equal [@p1, @p2, @p3], @net.places
      assert_equal [:A, :B, :C], @net.pp
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
        @t1 = @tç.new!( ɴ: "T1",
                        s: { @p1 => 1, @p2 => -1, @p3 => -1 },
                        rate: 0.01 )
        @net.include_transition! @t1
      end

      it "should expose its elements" do
        assert_equal [@t1], @net.transitions
        assert_equal [:T1], @net.tt
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
        @net.send( :place, @p1 ).must_equal @p1
        @net.send( :transition, @t1 ).must_equal @t1
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
          @t2 = @tç.new s: { @p2 => -1, @p3 => 1 }
          @net.include_transition! @t2
        end

        it "should expose its elements" do
          assert_equal [@t1, @t2], @net.transitions
          assert_equal [:T1, nil], @net.tt
          @net.tap{ |n| n.exclude_transition! @t1 }.exclude_transition! @t2
          @net.tap{ |n| n.exclude_place! @p3 }.pp.must_equal [:A, :B]
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
          assert_equal [:T1], @net.stoichiometric_tt_with_rate
          assert_equal [], @net.transitions_with_explicit_assignment_action
          assert_equal [], @net.transitions_with_assignment_action
          assert_equal [], @net.assignment_transitions
          assert_equal [], @net.tt_with_explicit_assignment_action
          assert_equal [], @net.tt_with_assignment_action
          assert_equal [], @net.assignment_tt
          assert_equal [@t1, @t2], @net.stoichiometric_transitions
          assert_equal [:T1, nil], @net.stoichiometric_tt
          assert_equal [], @net.nonstoichiometric_transitions
          assert_equal [], @net.nonstoichiometric_tt
          assert_equal [@t1], @net.timed_transitions
          assert_equal [:T1], @net.timed_tt
          assert_equal [@t2], @net.timeless_transitions
          assert_equal [nil], @net.timeless_tt
          assert_equal [@t1], @net.transitions_with_rate
          assert_equal [:T1], @net.tt_with_rate
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
    @pç = pç = Class.new( ::YPetri::Place )
    @tç = tç = Class.new( ::YPetri::Transition )
    @nç = nç = Class.new( ::YPetri::Net )
    [ @pç, @tç, @nç ].each { |klass|
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
                  flux: 0.1
    @t2 = @tç.new name: "T2",
                  s: { @p1 => -1, @p3 => 1 },
                  flux: λ { |a| a * 0.5 }
    @t3 = @tç.new name: "T3",
                  s: { @p1 => -1, @p2 => -1, @p4 => 1 },
                  domain: @p3, flux: λ { |a| a * 0.5 }
    @net = @nç.new << @p1 << @p2 << @p3 << @p4 << @p5
    @net.include_transition! @t1
    @net.include_transition! @t2
    @net << @t3
    @s = YPetri::Simulation.new net: @net,
                                place_clamps: { @p1 => 2.0, @p5 => 2.0 },
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
    @s.S_for_tS.must_equal Matrix.empty( 3, 0 )
  end

  it "has stoichiometry matrix for 4. Sr transitions" do
    @s.S_for_TSr.must_equal Matrix.empty( 3, 0 )
  end

  it "has stoichiometry matrix for 6. SR transitions" do
    @s.S_for_SR.must_equal Matrix[[-1,  0, -1], [0, 1, 0], [1, 0, 1]]
    @s.S.must_equal @s.S_for_SR
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
    @s.Δ_closures_for_ts.must_equal []
    @s.Δ_if_ts_fire_once.must_equal Matrix.zero( @s.free_pp.size, 1 )
  end

  it "2. handles Tsr transitions" do
    @s.Δ_closures_for_Tsr.must_equal []
    @s.Δ_for_Tsr( 1.0 ).must_equal Matrix.zero( @s.free_pp.size, 1 )
  end

  it "3. handles tS transitions" do
    @s.action_closures_for_tS.must_equal []
    @s.action_vector_for_tS.must_equal Matrix.column_vector( [] )
    @s.α_for_t.must_equal Matrix.column_vector( [] )
    @s.Δ_if_tS_fire_once.must_equal Matrix.zero( @s.free_pp.size, 1 )
  end

  it "4. handles TSr transitions" do
    @s.action_closures_for_TSr.must_equal []
    @s.action_closures_for_Tr.must_equal []
    @s.action_vector_for_TSr( 1.0 ).must_equal Matrix.column_vector( [] )
    @s.action_vector_for_Tr( 1.0 ).must_equal Matrix.column_vector( [] )
    @s.Δ_for_TSr( 1.0 ).must_equal Matrix.zero( @s.free_pp.size, 1 )
  end

  it "5. handles sR transitions" do
    assert_equal [], @s.rate_closures_for_sR
    assert_equal [], @s.rate_closures_for_s
    @s.gradient_for_sR.must_equal Matrix.zero( @s.free_pp.size, 1 )
    @s.Δ_Euler_for_sR( 1.0 ).must_equal Matrix.zero( @s.free_pp.size, 1 )
  end

  it "6. handles stoichiometric transitions with rate" do
    @s.rate_closures_for_SR.size.must_equal 3
    @s.rate_closures_for_S.size.must_equal 3
    @s.rate_closures.size.must_equal 3
    @s.flux_vector_for_SR.must_equal Matrix.column_vector( [ 0.4, 1.0, 1.5 ] )
    @s.φ_for_SR.must_equal @s.flux_vector
    @s.SR_tt( :φ_for_SR ).must_equal( { T1: 0.4, T2: 1.0, T3: 1.5 } )
    @s.Euler_action_vector_for_SR( 1 )
      .must_equal Matrix.column_vector [ 0.4, 1.0, 1.5 ]
    @s.SR_tt( :Euler_action_for_SR, 1 ).must_equal( T1: 0.4, T2: 1.0, T3: 1.5 )
    @s.Δ_Euler_for_SR( 1 ).must_equal Matrix[[-1.9], [1.0], [1.9]]
    @s.free_pp( :Δ_Euler_for_SR, 1 ).must_equal( { P2: -1.9, P3: 1.0, P4: 1.9 } )
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
        m = @sim.step!.marking
        assert_in_delta 0.8, m[ 0 ], 1e-9
        assert_in_delta 1.8, m[ 1 ], 1e-9
        assert_in_delta 3.2, m[ 2 ], 1e-9
      end

      it "should behave" do
        assert_in_delta 0, ( Matrix.column_vector( [-0.02, -0.02, 0.02] ) -
                             @sim.ΔE( 0.1 ) ).column( 0 ).norm, 1e-9
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
        m = @sim.step!.marking
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
        @sim.S.must_equal Matrix[ [-1, 0, 1] ].t
        m = @sim.step!.marking
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
      @sim.marking.must_equal [1.0, 0.6, 3.0]
      @t3.stoichiometric?.must_equal true
      @t3.timed?.must_equal true
      @t3.has_rate?.must_equal true
      @sim.gradient.must_equal Matrix.cv [-0.3, 0.0, 0.3]
      @sim.Δ_Euler.must_equal Matrix.cv [-0.3, 0.0, 0.3]
      @sim.step!
      @sim.marking_vector.must_equal Matrix.cv [0.7, 0.6, 3.3]
      @sim.euler_step!
      @sim.run!
      @sim.marking_vector.map( &[:round, 5] )
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
    a = @w.Place.new!( default_marking: 1.0, name: "AA" )
    b = @w.Place.new!( default_marking: 2.0, name: "BB" )
    c = @w.Place.new!( ɴ: "CC", default_marking: 3.0 )
    t1 = @w.Transition.new! s: { a => -1, b => -1, c => 1 },
                            rate: 0.1,
                            ɴ: "AA_BB_assembly"
    t2 = @w.Transition.new! ɴ: "AA_appearing",
                            codomain: a,
                            rate: λ{ 0.1 },
                            stoichiometry: 1
    @pp, @tt = [a, b, c], [t1, t2]
    @f_name = "test_output.csv"
    @w.set_imc @pp.τBᴍHτ( &:default_marking )
    @w.set_ssc step: 0.1, sampling: 10, target_time: 50
    @w.set_cc( {} )
    @sim = @w.new_timed_simulation
    File.delete @f_name rescue nil
  end

  it "should present places, transitions, nets, simulations" do
    assert_kind_of ::YPetri::Net, @w.Net::Top
    assert_equal @pp[0], @w.place( "AA" )
    assert_equal :AA, @w.p( @pp[0] )
    assert_equal @tt[0], @w.transition( "AA_BB_assembly" )
    assert_equal :AA_appearing, @w.t( @tt[1] )
    assert_equal @pp, @w.places
    assert_equal @tt, @w.transitions
    assert_equal 1, @w.nets.size
    assert_equal 1, @w.simulations.size
    assert_equal 0, @w.cc.size
    assert_equal 3, @w.imc.size
    assert [0.1, 10, 50].each { |e| @w.ssc.include? e }
    assert_equal @sim, @w.simulation
    assert_equal [:Base], @w.clamp_collections.keys
    assert_equal [:Base], @w.initial_marking_collections.keys
    assert_equal [:Base], @w.simulation_settings_collections.keys
    assert_equal [:AA, :BB, :CC], @w.pp
    assert_equal [:AA_BB_assembly, :AA_appearing], @w.tt
    assert_equal [:Top], @w.nn
  end

  it "should simulate" do
    assert_equal 1, @w.simulations.size
    assert_kind_of( ::YPetri::Simulation, @w.simulation )
    assert_equal 2, @w.simulation.SR_transitions.size
    @tt[0].domain.must_equal [ @pp[0], @pp[1] ]
    @tt[1].domain.must_equal []
    assert_equal [0.2, 0.1], @w.simulation.φ.column_to_a
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
    @m.net_point_to @m.workspace.net( :Top )
    @m.net.must_equal @m.workspace.Net::Top
    # --- simulation point related assets ---
    @m.simulation_point_reset
    @m.simulation_point_to nil
    @m.simulation.must_equal nil
    @m.simulation_point_position.must_equal nil
    # --- cc point related assets ---
    @m.cc_point_reset
    @m.cc_point_to :Base
    @m.cc.must_equal @m.workspace.clamp_collection
    @m.cc.wont_equal :Base
    @m.cc_point_position.must_equal :Base
    # --- imc point related assets ---
    @m.imc_point_reset
    @m.imc_point_to :Base
    @m.imc.must_equal @m.workspace.initial_marking_collection
    @m.imc.wont_equal :Base
    @m.imc_point_position.must_equal :Base
    # --- ssc point related assets ---
    @m.ssc_point_reset
    @m.ssc_point_to :Base
    @m.ssc.must_equal @m.workspace.simulation_settings_collection
    @m.ssc.wont_equal :Base
    @m.ssc_point_position.must_equal :Base
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
      @constant_flux_t = @m.Transition ɴ: "Tq", s: { Q: 1 }, rate: λ{ 0.02 }
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
end


# **************************************************************************
# ACCEPTANCE TESTS
# **************************************************************************

# describe "Token game" do
#   before do
#     @m = YPetri::Manipulator.new
#     @m.Place name: "A"
#     @m.Place name: "B"
#     @m.Place name: "C", marking: 7.77
#     @m.Transition name: "A2B", stoichiometry: { A: -1, B: 1 }
#     @m.Transition name: "C_decay", stoichiometry: { C: -1 }, rate: 0.05
#   end

#   it "should work" do
#     @m.place( :A ).marking = 2
#     @m.place( :B ).marking = 5
#     @m.places.map( &:name ).must_equal [:A, :B, :C]
#     @m.places.map( &:marking ).must_equal [2, 5, 7.77]
#     @m.transition( :A2B ).connectivity.must_equal [ @m.place( :A ), @m.place( :B ) ]
#     @m.transition( :A2B ).fire!
#     @m.places.map( &:marking ).must_equal [1, 6, 7.77]
#     @m.transition( :A2B ).fire!
#     @m.place( :A ).marking.must_equal 0
#     @m.place( :B ).marking.must_equal 7
#     2.times do @m.transition( :C_decay ).fire! 1 end
#     @m.transition( :C_decay ).fire! 0.1
#     200.times do @m.transition( :C_decay ).fire! 1 end
#     assert_in_delta @m.place( :C ).marking, 0.00024, 0.00001
#   end
# end

# describe "Basic use of TimedSimulation" do
#   before do
#     @m = YPetri::Manipulator.new
#     @m.Place( name: "A", default_marking: 0.5 )
#     @m.Place( name: "B", default_marking: 0.5 )
#     @m.Transition( name: "A_pump",
#                    stoichiometry: { A: -1 },
#                    rate: proc { 0.005 } )
#     @m.Transition( name: "B_decay",
#                    stoichiometry: { B: -1 },
#                    rate: 0.05 )
#   end

#   it "should work" do
#     @m.net.must_be_kind_of ::YPetri::Net
#     @m.run!
#     @m.simulation.must_be_kind_of ::YPetri::TimedSimulation
#     @m.plot_recording
#     sleep 3
#   end
# end

# describe "Graphviz visualization" do
#   before do
#     @m = YPetri::Manipulator.new
#     @m.Place name: :A, m!: 1
#     @m.Place name: :B, m!: 1.5
#     @m.Place name: :C, m!: 2
#     @m.Place name: :D, m!: 2.5
#     @m.Transition name: :A_pump, s: { A: -1 }, rate: proc { 0.005 }
#     @m.Transition name: :B_decay, s: { B: -1 }, rate: 0.05
#     @m.Transition name: :C_guard, assignment: true, codomain: :C, action: λ { 2 }
#   end

#   it "should work" do
#     @m.net.visualize
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
#     AMP = @m.Place( name: :AMP, m!: 8695.0 )
#     ADP = @m.Place( name: :ADP, m!: 6521.0 )
#     ATP = @m.Place( name: :ATP, m!: 3152.0 )
#     Deoxycytidine = @m.Place( name: :Deoxycytidine, m!: 0.5 )
#     DeoxyCTP = @m.Place( name: :DeoxyCTP, m!: 1.0 )
#     DeoxyGMP = @m.Place( name: :DeoxyGMP, m!: 1.0 )
#     UMP_UDP_pool = @m.Place( name: :UMP_UDP_pool, m!: 2737.0 )
#     DeoxyUMP_DeoxyUDP_pool = @m.Place( name: :DeoxyUMP_DeoxyUDP_pool, m!: 0.0 )
#     DeoxyTMP = @m.Place( name: :DeoxyTMP, m!: 3.3 )
#     DeoxyTDP_DeoxyTTP_pool = @m.Place( name: :DeoxyTDP_DeoxyTTP_pool, m!: 5.0 )
#     Thymidine = @m.Place( name: :Thymidine, m!: 0.5 )
#     TK1 = @m.Place( name: :TK1, m!: 100_000 )
#     TYMS = @m.Place( name: :TYMS, m!: 100_000 )
#     RNR = @m.Place( name: :RNR, m!: 100_000 )
#     TMPK = @m.Place( name: :TMPK, m!: 100_000 )
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
#     @m.Transition name: :TK1_Thymidine_DeoxyTMP,
#                   domain: [ Thymidine, TK1, DeoxyTDP_DeoxyTTP_pool, DeoxyCTP, Deoxycytidine, AMP, ADP, ATP ],
#                   stoichiometry: { Thymidine: -1, DeoxyTMP: 1 },
#                   rate: proc { |rc, e, pool1, ci2, ci3, master1, master2, master3|
#                                ci1 = pool1 * master3 / ( master2 + master3 )
#                                MMi.( rc, TK1_a, TK1_kDa, e, TK1_Thymidine_Km,
#                                      ci1 => 13.5, ci2 => 0.8, ci3 => 40.0 ) }
#     @m.Transition name: :TYMS_DeoxyUMP_DeoxyTMP,
#                   domain: [ DeoxyUMP_DeoxyUDP_pool, TYMS, AMP, ADP, ATP ],
#                   stoichiometry: { DeoxyUMP_DeoxyUDP_pool: -1, DeoxyTMP: 1 },
#                   rate: proc { |pool, e, master1, master2, master3|
#                           rc = pool * master2 / ( master1 + master2 )
#                           MMi.( rc, TYMS_a, TYMS_kDa, e, TYMS_DeoxyUMP_Km ) }
#     @m.Transition name: :RNR_UDP_DeoxyUDP,
#                   domain: [ UMP_UDP_pool, RNR, DeoxyUMP_DeoxyUDP_pool, AMP, ADP, ATP ],
#                   stoichiometry: { UMP_UDP_pool: -1, DeoxyUMP_DeoxyUDP_pool: 1 },
#                   rate: proc { |pool, e, master1, master2, master3|
#                                rc = pool * master2 / ( master1 + master2 )
#                                MMi.( rc, RNR_a, RNR_kDa, e, RNR_UDP_Km ) }
#     @m.Transition name: :DNA_polymerase_consumption_of_DeoxyTTP,
#                   stoichiometry: { DeoxyTDP_DeoxyTTP_pool: -1 },
#                   rate: proc { DNA_creation_speed / 4 }
#     @m.Transition name: :TMPK_DeoxyTMP_DeoxyTDP,
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
#     sleep 3
#   end
# end

# describe "Use of TimedSimulation with units" do
#   before do
#     require 'sy'

#     @m = YPetri::Manipulator.new

#     # === General assumptions
#     Cytoplasm_volume = 5.0e-11.l
#     Pieces_per_concentration = SY::Nᴀ * Cytoplasm_volume

#     # === Simulation settings
#     @m.set_step 60.s
#     @m.set_target_time 10.min
#     @m.set_sampling 120.s

#     # === Places
#     AMP = @m.Place m!: 8695.0.µM
#     ADP = @m.Place m!: 6521.0.µM
#     ATP = @m.Place m!: 3152.0.µM
#     Deoxycytidine = @m.Place m!: 0.5.µM
#     DeoxyCTP = @m.Place m!: 1.0.µM
#     DeoxyGMP = @m.Place m!: 1.0.µM
#     U12P = @m.Place m!: 2737.0.µM
#     DeoxyU12P = @m.Place m!: 0.0.µM
#     DeoxyTMP = @m.Place m!: 3.3.µM
#     DeoxyT23P = @m.Place m!: 5.0.µM
#     Thymidine = @m.Place m!: 0.5.µM
#     TK1 = @m.Place m!: 100_000.unit.( SY::MoleAmount ) / Cytoplasm_volume
#     TYMS = @m.Place m!: 100_000.unit.( SY::MoleAmount ) / Cytoplasm_volume
#     RNR = @m.Place m!: 100_000.unit.( SY::MoleAmount ) / Cytoplasm_volume
#     TMPK = @m.Place m!: 100_000.unit.( SY::MoleAmount ) / Cytoplasm_volume

#     # === Enzyme molecular masses
#     TK1_m = 24.8.kDa
#     TYMS_m = 66.0.kDa
#     RNR_m = 140.0.kDa
#     TMPK_m = 50.0.kDa

#     # === Specific activities of the enzymes
#     TK1_a = 5.40.µmol.min⁻¹.mg⁻¹
#     TYMS_a = 3.80.µmol.min⁻¹.mg⁻¹
#     RNR_a = 1.00.µmol.min⁻¹.mg⁻¹
#     TMPK_a = 0.83.µmol.min⁻¹.mg⁻¹

#     # === Clamps
#     @m.clamp AMP: 8695.0.µM, ADP: 6521.0.µM, ATP: 3152.0.µM
#     @m.clamp Deoxycytidine: 0.5.µM, DeoxyCTP: 1.0.µM, DeoxyGMP: 1.0.µM
#     @m.clamp Thymidine: 0.5.µM
#     @m.clamp U12P: 2737.0.µM

#     # === Function closures

#     # Vmax of an enzyme.
#     # 
#     Vmax_enzyme = lambda { |specific_activity, mass, enzyme_conc|
#       specific_activity * mass * enzyme_conc.( SY::Molecularity )
#     }

#     # Michaelis constant reduced for competitive inhibitors.
#     # 
#     Km_reduced = lambda { |km, ki_hash={}|
#       ki_hash.map { |concentration, ci_Ki|
#         concentration / ci_Ki }
#         .reduce( 1, :+ ) * km
#     }

#     # Occupancy of enzyme active sites at given concentration of reactants
#     # and competitive inhibitors.
#     # 
#     Occupancy = lambda { |ʀ_conc, ʀ_Km, cɪ_Kɪ={}|
#       ʀ_conc / ( ʀ_conc + Km_reduced.( ʀ_Km, cɪ_Kɪ ) )
#     }

#     # Michaelis and Menten equation with competitive inhibitors.
#     # 
#     MMi = MM_equation_with_inhibitors = lambda {
#       |ʀ_conc, ᴇ_specific_activity, ᴇ_mass, ᴇ_conc, ʀ_Km, cɪ_Kɪ={}|
#       Vmax_enzyme.( ᴇ_specific_activity, ᴇ_mass, ᴇ_conc ) *
#         Occupancy.( ʀ_conc, ʀ_Km, cɪ_Kɪ )
#     }

#     # === Michaelis constants of the enzymes involved.

#     TK1_Thymidine_Km = 5.0.µM
#     TYMS_DeoxyUMP_Km = 2.0.µM
#     RNR_UDP_Km = 1.0.µM
#     TMPK_DeoxyTMP_Km = 12.0.µM

#     # === DNA synthesis speed.

#     DNA_creation_speed = 3_000_000_000.unit.( SY::MoleAmount ) / 12.h / Cytoplasm_volume

#     # === Transitions

#     # Synthesis of TMP by TK1.
#     # 
#     TK1_Thymidine_DeoxyTMP = @m.Transition s: { Thymidine: -1, DeoxyTMP: 1 },
#       domain: [ Thymidine, TK1, DeoxyT23P, DeoxyCTP, Deoxycytidine, AMP, ADP, ATP ],
#         rate: proc { |rc, e, pool1, ci2, ci3, master1, master2, master3|
#                 ci1 = pool1 * master3 / ( master2 + master3 )
#                 MMi.( rc, TK1_a, TK1_m, e, TK1_Thymidine_Km,
#                       ci1 => 13.5.µM, ci2 => 0.8.µM, ci3 => 40.0.µM )
#               }

#     # Methylation of DeoxyUMP into TMP by TYMS.
#     TYMS_DeoxyUMP_DeoxyTMP = @m.Transition s: { DeoxyU12P: -1, DeoxyTMP: 1 },
#       domain: [ DeoxyU12P, TYMS, AMP, ADP, ATP ],
#         rate: proc { |pool, e, master1, master2, master3|
#                 rc = pool * master2 / ( master1 + master2 )
#                 MMi.( rc, TYMS_a, TYMS_m, e, TYMS_DeoxyUMP_Km )
#               }

#     # Reduction of UDP into DeoxyUDP by RNR.
#     RNR_UDP_DeoxyUDP = @m.Transition s: { U12P: -1, DeoxyU12P: 1 },
#       domain: [ U12P, RNR, DeoxyU12P, AMP, ADP, ATP ],
#         rate: proc { |pool, e, master1, master2, master3|
#                 rc = pool * master2 / ( master1 + master2 )
#                 MMi.( rc, RNR_a, RNR_m, e, RNR_UDP_Km )
#               }

#     # Consumption of TTP by DNA synthesis.
#     DeoxyTTP_to_DNA = @m.Transition s: { DeoxyT23P: -1 },
#         rate: proc { DNA_creation_speed / 4 }

#     # Phosphorylation of TMP into TDP-TTP pool.
#     TMPK_DeoxyTMP_DeoxyTDP = @m.Transition s: { DeoxyTMP: -1, TMPK: 0, DeoxyT23P: 1 },
#       domain: [ DeoxyTMP, TMPK, ADP, DeoxyT23P, DeoxyGMP, AMP, ATP ],
#         rate: proc { |rc, e, ci1, pool, ci4, master1, master3|
#                 master2 = ci1
#                 ci2 = pool * master2 / ( master2 + master3 )
#                 ci3 = pool * master3 / ( master2 + master3 )
#                 MMi.( rc, TMPK_a, TMPK_m, e, TMPK_DeoxyTMP_Km,
#                       ci1 => 250.0.µM, ci2 => 30.0.µM, ci3 => 750.µM, ci4 => 117.µM )
#               }
#   end

#   it "should work" do
#     # === Simulation execution
#     @m.run!
#     # === Plotting of the results
#     @m.plot_recording
#     sleep 20
#   end
# end
