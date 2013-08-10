#! /usr/bin/ruby
# encoding: utf-8

gem 'minitest', '=4.7.4'
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
    @p1 = pç.send :new, default_marking: 1.0
    @p2 = pç.send :new, default_marking: 2.0
    @p3 = pç.send :new, default_marking: 3.0
    @p4 = pç.send :new, default_marking: 4.0
    @p5 = pç.send :new, default_marking: 5.0
  end

  describe "ts transitions (timeless nonstoichiometric)" do
    # Note: ts transitions require a function, and thus are always functional
    before do
      @t1 = @ç.send :new, codomain: [ @p1, @p3 ], domain: @p2, action: -> a { [ a, a ] }
      @t2 = @ç.send :new, codomain: [ @p1, @p3 ] do |t| [ t, t ] end
      @t3 = @ç.send :new, action: -> { [ 0.5, 0.5 ] }, codomain: [ @p1, @p3 ]
    end

    it "should raise errors for bad parameters" do
      # codomain omitted
      -> { @ç.send :new, domain: @p2, action: -> t { [ t, t ] } }
        .must_raise ArgumentError
      # mangled codomain
      -> { @ç.send :new, codomain: [ @p1, :a ], action: -> t { [ t, t ] } }
        .must_raise TypeError
      # domain omitted
      -> { @ç.send :new, codomain: [ @p1, :a ], action: -> t { [ t, t ] } }
        .must_raise TypeError
      # action closure arity greater than the domain
      -> { @ç.send :new, codomain: [ @p1, @p3 ], action: -> t { [ t, t ] }, domain: [] }
        .must_raise TypeError
    end

    it "should work" do
      @t1.type.must_equal :ts
      @t1.domain.must_equal [@p2]
      @t1.action_arcs.must_equal [@p1, @p3]
      assert @t1.functional?
      assert [@t1, @t2, @t3].all? { |t| t.timeless? }
      assert [@t1, @t2, @t3].all? { |t| t.s? }
      # Now let's flex them:
      @t1.fire!
      [@p1.m, @p3.m].must_equal [3, 5]
      @t3.fire!
      [@p1.m, @p3.m].must_equal [3.5, 5.5]
      @t2.fire!
      [@p1.m, @p3.m].must_equal [7.0, 9.0]
      @t1.codomain_marking.must_equal [@p1.m, @p3.m]
      @t1.domain_marking.must_equal [@p2.m]
      @t1.zero_action.must_equal [0, 0]
    end
  end

  describe "tS transitions" do
    before do
      @t1 = @ç.send :new, s: { @p5 => -1, @p1 => 1 }, action: proc { 1 }
      @t2 = @ç.send :new, s: { @p5 => -1, @p1 => 1 } # should be "functionless"
    end

    it "should work" do
      @t1.type.must_equal :tS
      @t2.type.must_equal :tS
      @t1.codomain.must_equal [@p5, @p1]
      @t2.codomain.must_equal [@p5, @p1]
      assert @t1.functional?
      assert ! @t2.functional? # "functionless"
      assert ! @t1.timed?
      assert ! @t2.timed?
      @t1.stoichiometry.must_equal [-1, 1]
      @t2.stoichiometry.must_equal [-1, 1]
      @t1.stoichio.must_equal( { @p5 => -1, @p1 => 1 } )
      @t2.stoichio.must_equal( { @p5 => -1, @p1 => 1 } )
      @t1.s.must_equal( { @p5.object_id => -1, @p1.object_id => 1 } ) 
      @t2.s.must_equal( { @p5.object_id => -1, @p1.object_id => 1 } )
      @t1.domain.must_equal [@p5] # inferred domain
      @t2.domain.must_equal [] # domain is empty in functionless transitions!
      [@p1.m, @p5.m].must_equal [1, 5]
      @t1.fire!
      [@p1.m, @p5.m].must_equal [2, 4]
      @t2.fire!
      [@p1.m, @p5.m].must_equal [3, 3]
    end
  end


  describe "Ts transitions" do
    before do
      @t1 = @ç.send :new, domain: @p5, codomain: [@p5, @p1], rate: proc { [-1, 1] }
    end

    it "should work" do
      @t1.type.must_equal :Ts
      @t1.codomain.must_equal [@p5, @p1]
      assert @t1.functional?
      assert @t1.timed?
      @t1.domain.must_equal [@p5]
      [@p1.m, @p5.m].must_equal [1, 5]
      @t1.rate_closure.arity.must_equal 0
      @t1.fire! 0.5
      [@p1.m, @p5.m].must_equal [1.5, 4.5]
    end
  end

  describe "TS transitions (timed stoichiometric)" do
    before do
      # This should give standard mass action by magic:
      @TS1 = @ç.send :new, s: { @p1 => -1, @p2 => -1, @p4 => 1 }, rate: 0.1
      # While this has custom closure:
      @TS2 = @ç.send :new, s: { @p1 => -1, @p3 => 1 }, rate: -> a { a * 0.5 }
      # While this one even has domain explicitly specified:
      @TS3 = @ç.send :new, s: { @p1 => -1, @p2 => -1, @p4 => 1 },
                     upstream_arcs: @p3, rate: -> a { a * 0.5 }
    end

    it "should init and work" do
      @TS1.timed?.must_equal true
      @TS1.upstream_arcs.must_equal [@p1, @p2]
      @TS1.action_arcs.must_equal [@p1, @p2, @p4]
      @TS2.domain.must_equal [@p1]
      @TS2.action_arcs.must_equal [@p1, @p3]
      @TS3.domain.must_equal [@p3]
      @TS3.action_arcs.must_equal [@p1, @p2, @p4]
      # and flex them
      @TS1.fire! 1.0
      [@p1, @p2, @p4].map( &:marking ).must_equal [0.8, 1.8, 4.2]
      @TS2.fire! 1.0
      [@p1, @p3].map( &:marking ).must_equal [0.4, 3.4]
      # the action t3 cannot fire with delta time 1.0
      -> { @TS3.fire! 1.0 }.must_raise YPetri::GuardError
      [@p1, @p2, @p3, @p4].map( &:marking ).must_equal [0.4, 1.8, 3.4, 4.2]
      # but it can fire with eg. delta time 0.1
      @TS3.fire! 0.1
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
    @tç = tç = Class.new YPetri::Transition
    @pç = pç = Class.new YPetri::Place
    [ tç, pç ].each { |ç|
      ç.class_exec {
        define_method :Place do pç end
        define_method :Transition do tç end
        private :Place, :Transition
      }
    }
    @a = @pç.send :new, default_marking: 1.0
    @b = @pç.send :new, default_marking: 2.0
    @c = @pç.send :new, default_marking: 3.0
  end

  describe "Place" do
    it "should have #register_ustream/downstream_transition methods" do
      @t1 = @tç.send :new, s: {}
      @a.instance_variable_get( :@upstream_arcs ).must_equal []
      @a.instance_variable_get( :@downstream_arcs ).must_equal []
      @a.send :register_upstream_transition, @t1
      @a.instance_variable_get( :@upstream_arcs ).must_equal [ @t1 ]
    end
  end

  describe "upstream and downstream reference methods" do
    before do
      @t1 = @tç.send :new, s: { @a => -1, @b => 1 }, rate: 1
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
      @p = @pç.send :new, default_marking: 1.0
      @t = @tç.send :new, codomain: @p, action: -> { 1 }, assignment_action: true
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
