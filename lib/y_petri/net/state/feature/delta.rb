# encoding: utf-8

# Change of a Petri net place caused by a certain set of transitions.
# 
class YPetri::Net::State::Feature::Delta < YPetri::Net::State::Feature
  attr_reader :place, :transitions
  alias tt transitions

  class << self
    # Customization of the Class#parametrize method.
    # 
    def parametrize *args
      Class.instance_method( :parametrize ).bind( self ).( *args ).tap do |ç|
        # First, prepare the instance registry.
        hsh = Hash.new do |ꜧ, id|
          if id.is_a? self then # missing key "id" is a Delta instance
            ꜧ[ [ id.place, transitions: id.transitions.sort_by( &:object_id ) ] ]
          else
            p = id.fetch( 0 )
            tt = id.fetch( 1 ).fetch( :transitions ) # value of :transitions key
            tt_array = Array( tt )
            if tt == tt_array then
              if p.is_a? ç.net.Place and tt.all? { |t| t.is_a? ç.net.Transition }
                if tt == tt.sort_by( &:object_id ) then
                  # Cache the instance.
                  ꜧ[ id ] = if tt.all? &:timed? then
                              ç.timed( *id )
                            elsif tt.all? &:timeless? then
                              fail TypeError, "Net::State::Feature::Delta does " +
                                "not admit A transitions!" if tt.any? &:A?
                              ç.timeless( *id )
                            else
                              fail TypeError, "Net::State::Feature::Delta only " +
                                "admits the transition sets that are either " +
                                "all timed, or all timeless!"
                            end
                else
                  ꜧ[ [ p, transitions: tt.sort_by( &:object_id ) ] ]
                end
              else # convert place and transition ids to places and transitions
                ꜧ[ [ ç.net.place( p ), transitions: ç.net.Transitions( tt ) ] ]
              end
            else
              ꜧ[ [ p, transitions: tt_array ] ]
            end
          end
        end
        # Then, assign it to the :@instances variable.
        ç.instance_variable_set :@instances, hsh
      end # tap
    end # def parametrize

    attr_reader :instances

    alias __new__ new

    # Timed delta feature constructor. Takes a place, and an array of timed
    # transition identifiers supplied as +:transitions: parameter.
    # 
    def timed place, transitions: net.T_tt
      tt = begin
             net.T_Transitions( transitions )
           rescue TypeError => err
             msg = "Transitions #{transitions} not recognized as timed " +
               "transitions in #{net}! (%s)"
             raise TypeError, msg % err
           end
      __new__( place, transitions: tt )
        .tap { |inst| inst.instance_variable_set :@timed, true }
    end

    # Timeless delta feature constructor. Takes a place, and an array of
    # timeless transition identifiers as +:transitions: parameter.
    # 
    def timeless place, transitions: net.t_tt
      tt = begin
             net.t_Transitions( transitions )
           rescue TypeError => err
             msg = "Transitions #{transitions} not recognized as timed " +
               "transitions in #{net}! (%s)"
             raise TypeError, msg % err
           end
      __new__( place, transitions: net.t_Transitions( transitions ) )
        .tap { |inst| inst.instance_variable_set :@timed, false }
    end

    # Constructor #new is redefined to use instance cache.
    # 
    def new *args
      return instances[ *args ] if args.size == 1
      instances[ args ]
    end
    alias of new
  end

  # The constructor of a delta feature takes one ordered argument (place
  # identifier), and one named argument, +:transitions+, expecting an array
  # of transition identifiers, whose contribution is taken into account in
  # this delta feature.
  # 
  def initialize place, transitions: net.tt
    @place = net.place( place )
    @transitions = net.Transitions( transitions )
  end

  # Extracts the value of this feature from the target (eg. a simulation).
  # If the receiver delta feature is timed, this method requires an additional
  # named argument +:delta_time+, alias +:Δt+.
  # 
  def extract_from arg, **named_args
    case arg
    when YPetri::Simulation then
      if timed? then
        arg.send( :T_Transitions, transitions )
          .delta( named_args.must_have :delta_time, syn!: :Δt ).fetch( place )
      else
        arg.send( :t_Transitions, transitions ).delta.fetch( place )
      end
    else
      fail TypeError, "Argument type not supported!"
    end
  end

  # Is the delta feature timed?
  # 
  def timed?
    @timed
  end

  # Opposite of +#timed?+.
  # 
  def timeless?
    ! timed?
  end

  # Type of this feature.
  # 
  def type
    :delta
  end

  # A string briefly describing this delta feature.
  # 
  def to_s
    label
  end

  # Label for the delta feature (to use in graphics etc.)
  # 
  def label
    "Δ:#{place.name}:%s" %
      if transitions.size == 1 then
        transitions.first.name || transitions.first
      else
        "#{transitions.size}tt"
      end
  end

  # Inspect string of the delta feature.
  # 
  def inspect
    "<Feature::Delta Δ:#{place.name || place}:[%s]>" %
      transitions.names( true ).join( ', ' )
  end

  # Delta features are equal if they are of equal PS and refer to
  # the same place and transition set.
  # 
  def == other
    other.is_a? net.State.Feature.Delta and
      place == other.place && transitions == other.transitions
  end
end # class YPetri::Net::State::Feature::Delta
