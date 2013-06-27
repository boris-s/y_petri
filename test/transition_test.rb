#! /usr/bin/ruby
# -*- coding: utf-8 -*-

require 'minitest/spec'
require 'minitest/autorun'
require 'y_support/typing'

require_relative '../lib/y_petri'     # tested component itself

# require 'y_petri'
# require 'sy'

# **************************************************************************
# Test of Transition class, part I.
# **************************************************************************
#
describe ::YPetri::Transition do
  before do
    @ç = ç = Class.new ::YPetri::Transition
    @pç = pç = Class.new ::YPetri::Place
    [ ç, pç ].each do |ç|
      ç.class_exec {
        define_method :Place do pç end
        define_method :Transition do ç end
        private :Place, :Transition
      }
    end
    @p1 = pç.new default_marking: 1.0
    @p2 = pç.new default_marking: 2.0
    @p3 = pç.new default_marking: 3.0
    @p4 = pç.new default_marking: 4.0
    @p5 = pç.new default_marking: 5.0
  end

  describe "ts transitions (timeless nonstoichiometric)" do
    # Note: ts transitions require a function, and thus are always functional
    before do
      @t1 = @ç.new codomain: [ @p1, @p3 ], domain: @p2, action: -> a { [ a, a ] }
      # saying that the transition is timed saves the day here:
      @t2 = @ç.new codomain: [ @p1, @p3 ], action: -> t { [ t, t ] }, timed: true
      # Only when the domain is unary, is the closure allowed to be timeless:
      @t3 = @ç.new codomain: [ @p1, @p3 ], action: -> t { [ t, t ] }, timed: false, domain: [ @p2 ]
      # With nullary action closure, timeless is implied, so this is allowed
      @t4 = @ç.new action: -> { [ 0.5, 0.5 ] }, codomain: [ @p1, @p3 ]
      # ... also for stoichiometric variety
      @t5 = @ç.new action: -> { 0.5 }, codomain: [ @p1, @p3 ], s: [ 1, 1 ]
    end

    it "should raise errors for bad parameters" do
      # omitting the domain should raise ArgumentError about too much ambiguity:
      -> { @ç.new codomain: [ @p1, @p3 ], action: -> t { [ t, t ] } }
        .must_raise ArgumentError
      # saying that the transition is timeless points to a conflict:
      -> { @ç.new codomain: [ @p1, @p3 ], action: -> t { [ t, t ] }, timeless: true }
        .must_raise ArgumentError
    end

    it "should initialize and perform" do
      @t1.domain.must_equal [@p2]
      @t1.action_arcs.must_equal [@p1, @p3]
      assert @t1.functional?
      assert @t1.timeless?
      assert @t2.timed?
      assert [@t3, @t4, @t5].all? { |t| t.timeless? }
      assert @t2.rateless?
      # Now let's flex them:
      @t1.fire!
      [@p1.m, @p3.m].must_equal [3, 5]
      @t3.fire!
      [@p1.m, @p3.m].must_equal [5, 7]
      @t4.fire!
      [@p1.m, @p3.m].must_equal [5.5, 7.5]
      @t5.fire!
      [@p1.m, @p3.m].must_equal [6, 8]
      # now t2 for firing requires delta time
      @t2.fire! 1
      [@p1.m, @p3.m].must_equal [7, 9]
      @t2.fire! 0.1
      [@p1.m, @p3.m ].must_equal [7.1, 9.1]
      # let's change @p2 marking
      @p2.m = 0.1
      @t1.fire!
      assert_in_epsilon 7.2, @p1.marking, 1e-9
      assert_in_epsilon 9.2, @p3.marking, 1e-9
      # let's test #domain_marking, #codomain_marking, #zero_action
      @t1.codomain_marking.must_equal [@p1.m, @p3.m]
      @t1.domain_marking.must_equal [@p2.m]
      @t1.zero_action.must_equal [0, 0]
    end
  end

  describe "Tsr transitions (timed rateless non-stoichiometric)" do
    #LATER: To save time, I omit the full test suite.
  end

  describe "tS transitions (timeless stoichiometric)" do
    describe "functionless tS transitions" do
      # For functionless tS transitions, stoichiometric vector must be given,
      # from which the action closure is then generated.

      before do
        # tS transition with only stoichiometric vector, as hash
        @ftS1 = @ç.new stoichiometry: { @p1 => 1 }
        # tS transition with only stoichiometric vector, as array + codomain
        @ftS2 = @ç.new stoichiometry: 1, codomain: @p1
        # :stoichiometry keyword is aliased as :s
        @ftS3 = @ç.new s: 1, codomain: @p1
        # :codomain is aliased as :action_arcs
        @ftS4 = @ç.new s: 1, action_arcs: @p1
        # square brackets (optional for size 1 vectors)
        @ftS5 = @ç.new s: [ 1 ], downstream: [ @p1 ]
        # another alias of :codomain is :downstream_places
        @ftS6 = @ç.new s: [ 1 ], downstream_places: [ @p1 ]
        # And now, collect all of the above:
        @tt = @ftS1, @ftS2, @ftS3, @ftS4, @ftS5, @ftS6
      end

      it "should work" do
        # ...should be the same, having a single action arc:
        assert @tt.all? { |t| t.action_arcs == [@p1] }
        # timeless:
        assert @tt.all? { |t| t.timeless? }
        # rateless:
        assert @tt.all? { |t| t.rateless? }
        assert @tt.all? { |t| not t.has_rate? }
        # no assignment action
        assert @tt.all? { |t| not t.assignment_action? }
        # not considered functional
        assert @tt.all? { |t| t.functionless? }
        assert @tt.all? { |t| not t.functional? }
        # and having nullary action closure
        assert @tt.all? { |t| t.action_closure.arity == 0 }
        # the transitions should be able to #fire!
        @ftS1.fire!
        # the difference is apparent: marking of place @p1 jumped to 2:
        @p1.marking.must_equal 2
        # but should not #fire (no exclamation mark) unless cocked
        assert !@ftS1.cocked?
        @ftS1.fire
        @p1.marking.must_equal 2
        # cock it
        @ftS1.cock
        assert @ftS1.cocked?
        # uncock again, just to test cocking
        @ftS1.uncock
        assert @ftS1.uncocked?
        @ftS1.cock
        assert !@ftS1.uncocked?
        @ftS1.fire
        @p1.marking.must_equal 3
        # enough playing, we'll reset @p1 marking
        @p1.reset_marking
        @p1.marking.must_equal 1
        # #action
        assert @tt.all? { |t| t.action == [1] }
        # #zero_action
        assert @tt.all? { |t| t.zero_action }
        # #domain_marking
        assert @tt.all? { |t| t.domain_marking == [] }
        # #codomain_marking
        assert @tt.all? { |t| t.codomain_marking == [@p1.m] }
        # #enabled?
        @p1.m.must_equal 1
        @p1.guard.( 1 ).must_equal 1
        @tt.each { |t| t.enabled?.must_equal true }
      end
    end

    describe "functional tS transitions" do
      # Closure supplied to tS transitions governs their action.

      before do
        # stoichiometry given as hash
        @FtS1 = @ç.new action_closure: ->{ 1 }, s: { @p1 => 1 }
        # :action_closure has alias :action
        @FtS2 = @ç.new action: ->{ 1 }, s: { @p1 => 1 }
        # stoichiometry given as array of coefficients + codomain
        @FtS3 = @ç.new s: 1, codomain: @p1, action: ->{ 1 }
        # Specifying +timed: false+ as well as +timeless: true+ should be OK.
        @FtS4 = @ç.new s: { @p1 => 1 }, action: ->{ 1 }, timed: false
        @FtS5 = @ç.new s: { @p1 => 1 }, action: ->{ 1 }, timeless: true
        # Even together in one statement:
        @FtS6 = @ç.new s: { @p1 => 1 }, action: ->{ 1 }, timed: false, timeless: true
        @tt = @FtS1, @FtS2, @FtS3, @FtS4, @FtS5, @FtS6
      end

      it "should reject bad parameters" do
        # # +timed: true+ should raise a complaint:
        # -> { @ç.new s: { @p1 => 1 }, action: ->{ 1 }, timed: true }
        #   .must_raise ArgumentError # constraint relaxed?
      end

      it "should init and perform" do
        assert @tt.all? { |t| t.action_arcs == [ @p1 ] }
        assert @tt.all? { |t| t.timeless? }
        assert @tt.all? { |t| not t.has_rate? }
        assert @tt.all? { |t| t.rateless? }
        assert @tt.all? { |t| not t.assignment_action? }
        assert @tt.all? { |t| not t.functionless? }
        assert @tt.all? { |t| t.functional? }
        # and having nullary action closure
        assert @tt.all? { |t| t.action_closure.arity == 0 }
        # the transitions should be able to #fire!
        @FtS1.fire!
        # no need for more testing here
      end
    end
  end

  describe "TSr transitions (timed rateless stoichiometric)" do
    # Sr transitions have an action closure, require a function block, and thus
    # are always functional. Their closure must take Δt as its first argument.

    #LATER: To save time, I omit the tests of TSr transitions for now.
  end

  describe "sR transitions (nonstoichiometric with rate)" do
    # Expect a function block with arity equal to their domain size, and output
    # arity equal to the codomain size.

    #LATER: To save time, I omit the full test suite.
  end

  describe "SR transitions (stoichiometric with rate)" do
    before do
      # This should give standard mass action by magic:
      @SR1 = @ç.new s: { @p1 => -1, @p2 => -1, @p4 => 1 }, rate: 0.1
      # While this has custom closure:
      @SR2 = @ç.new s: { @p1 => -1, @p3 => 1 }, rate: -> a { a * 0.5 }
      # While this one even has domain explicitly specified:
      @SR3 = @ç.new s: { @p1 => -1, @p2 => -1, @p4 => 1 },
                    upstream_arcs: @p3, rate: -> a { a * 0.5 }
    end

    it "should init and work" do
      @SR1.has_rate?.must_equal true
      @SR1.upstream_arcs.must_equal [@p1, @p2]
      @SR1.action_arcs.must_equal [@p1, @p2, @p4]
      @SR2.domain.must_equal [@p1]
      @SR2.action_arcs.must_equal [@p1, @p3]
      @SR3.domain.must_equal [@p3]
      @SR3.action_arcs.must_equal [@p1, @p2, @p4]
      # and flex them
      @SR1.fire! 1.0
      [@p1, @p2, @p4].map( &:marking ).must_equal [0.8, 1.8, 4.2]
      @SR2.fire! 1.0
      [@p1, @p3].map( &:marking ).must_equal [0.4, 3.4]
      # the action t3 cannot fire with delta time 1.0
      -> { @SR3.fire! 1.0 }.must_raise YPetri::GuardError
      [@p1, @p2, @p3, @p4].map( &:marking ).must_equal [0.4, 1.8, 3.4, 4.2]
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
    @tç = tç = Class.new YPetri::Transition
    @pç = pç = Class.new YPetri::Place
    [ tç, pç ].each { |ç|
      ç.class_exec {
        define_method :Place do pç end
        define_method :Transition do tç end
        private :Place, :Transition
      }
    }
    @a = @pç.new( default_marking: 1.0 )
    @b = @pç.new( default_marking: 2.0 )
    @c = @pç.new( default_marking: 3.0 )
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
      @a.upstream_arcs.must_equal [@t1]
      @b.downstream_arcs.must_equal []
      @b.ϝ.must_equal [@t1]
      @t1.upstream_arcs.must_equal [@a]
      @t1.action_arcs.must_equal [@a, @b]
    end
  end

  describe "assignment action transitions" do
    before do
      @p = @pç.new default_marking: 1.0
      @t = @tç.new codomain: @p, action: -> { 1 }, assignment_action: true
    end

    it "should work" do
      @p.marking = 3
      @p.marking.must_equal 3
      assert @t.assignment_action?
      @t.domain.must_equal []
      @t.action_closure.arity.must_equal 0
      @t.fire!
      @p.marking.must_equal 1
    end
  end # context assignment action transiotions
end