# encoding: utf-8

# Firing of a Petri net A transition.
# 
class YPetri::Net::State::Feature::Assignment < YPetri::Net::State::Feature
  attr_reader :place, :transition

  class << self
    # Customization of the Class#parametrize method.
    # 
    def parametrize *args
      Class.instance_method( :parametrize ).bind( self ).( *args ).tap do |ç|
        # Prepare the instance registry.
        hsh = Hash.new do |ꜧ, id|
          if id.is_a? self then # missing key "id" is an Assignment PS instance
            ꜧ[ [ id.place, transition: id.transition ] ]
          elsif id.is_a? ç.net.Place then # a single place
            ç.construct_from_a_place_with_single_upstream_A_transition( id )
          elsif id.is_a? Array and id.size == 1 then # single place again
            ç.construct_from_a_place_with_single_upstream_A_transition( id.first )
          elsif id.is_a? Array then
            p = id.fetch( 0 )
            t = id.fetch( 1 ).fetch( :transition )
            if p.is_a? ç.net.Place and t.is_a? ç.net.Transition then
              ꜧ[ id ] = ç.__new__( p, transition: t )
            else
              ꜧ[ [ ç.net.place( p ), transition: ç.net.transition( t ) ] ]
            end
          else
            ç.construct_from_a_place_with_single_upstream_A_transition( id )
          end
        end # Hash.new do
        # And assign it to @instances:
        ç.instance_variable_set :@instances, hsh
      end # tap
    end # def parametrize

    attr_reader :instances

    alias __new__ new

    # Constructor that enables special syntax of constructing
    # Feature::Assignment instance from a single place, as long
    # as this place has exactly 1 upstream A transition.
    # 
    def construct_from_a_place_with_single_upstream_A_transition( place )
      pl = net.place( place )
      aa = pl.upstream_arcs.select( &:A? )
      n = aa.size
      fail TypeError, "When constructing Feature::Assignment from a single" +
        "place, its upstream arcs must contain exactly one A transition! " +
        "(place #{pl} has #{n} upstream A transitions)" unless n == 1
      __new__( pl, transition: aa.first )
    end

    # Constructor #new is redefined to use instance cache.
    # 
    def new *args
      return instances[ *args ] if args.size == 1
      instances[ args ]
    end
    alias to new
  end

  # The constructor of an assignment feature takes 1 ordered and 1 named
  # (+:transition+) argument, which must identify the place and the transitions.
  # 
  def initialize place, transition: transition()
    @place = net.place( place )
    @transition = net.transition( transition )
    @place_index_in_codomain = @transition.codomain.index( @place ) or
      fail TypeError, "The place (#@place) must belong to the codomain of " +
        "the supplied A transition (#@transition)!"
  end

  # Extracts the receiver marking feature from the argument. This can be
  # typically a simulation instance.
  # 
  def extract_from arg, **nn
    case arg
    when YPetri::Simulation then
      # First, let's identify the relevant transition representation
      t = arg.send( :A_transitions, transition ).first
      # Then, let's get its assignment closure
      closure = t.assignment_closure
      # And finally, the feature extraction
      Array( closure.call )[ @place_index_in_codomain ]
    else
      fail TypeError, "Argument type not supported!"
    end
  end

  # Type of this feature.
  # 
  def type
    :assignment
  end

  # A string briefly describing the assignment feature.
  # 
  def to_s
    label
  end

  # Label for the firing feature (to use in the graphics etc.)
  # 
  def label
    "A:#{place.name}:#{transition.name}"
  end

  # Inspect string of the firing feature.
  # 
  def inspect
    "<Feature::Assignment to #{place.name or place} by #{transition.name or transition}>"
  end

  # Two assignment features are equal if their place and transition is equal.
  # 
  def == other
    other.is_a? net.State.Feature.Assignment and
      place == other.place && transition == other.transition
  end
end # YPetri::Net::State::Feature::Assignment
