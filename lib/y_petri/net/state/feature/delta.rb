# encoding: utf-8

# Change of a Petri net place caused by a certain set of transitions.
# 
class YPetri::Net::State::Feature::Delta < YPetri::Net::State::Feature
  attr_reader :place, :transitions, :step

  class << self
    def parametrize *args
      Class.instance_method( :parametrize ).bind( self ).( *args ).tap do |ç|
        # First, prepare the hash of instances.
        hsh = Hash.new do |ꜧ, id|
          if id.is_a? self then # missing key "id" is a Delta instance
            ꜧ[ [ id.place, transitions: id.transitions.sort( &:object_id ) ] ]
          else
            p = id.fetch( 0 )
            tt = id.fetch( 1 ).fetch( :transitions ) # value of :transitions key
            if p.is_a? ç.net.Place and tt.all? { |t| t.is_a? ç.net.Transition }
              if tt == tt.sort then
                # Cache the instance.
                ꜧ[ id ] = if tt.all? &:timed? then
                            ç.timed( *id )
                          elsif tt.all? &:timeless? then
                            ç.timeless( *id )
                          else
                            fail TypeError, "Net::State::Feature::Delta only " +
                              "admits the transition sets that are either " +
                              "all timed, or all timeless!"
                          end
              else
                ꜧ[ [ p, transitions: tt.sort ] ]
              end
            else # convert place and transition ids to places and transitions
              ꜧ[ [ ç.net.place( p ), transitions: ç.net.transitions( tt ) ] ]
            end
          end
        end
        # And then, assign it to the :@instances variable.
        ç.instance_variable_set :@instances, hsh
      end
    end

    attr_reader :instances

    alias __new__ new

    # Timed delta feature constructor. Takes a place, and an array of timed
    # transition identifiers supplied as +:transitions: parameter.
    # 
    def timed place, transitions: net.T_tt
      __new__( place, transitions: net.T_tt( transitions ) )
        .tap { |inst| inst.instance_variable_set :@timed, true }
    end

    # Timeless delta feature constructor. Takes a place, and an array of
    # timeless transition identifiers as +:transitions: parameter.
    # 
    def timeless place, transitions: net.t_tt
      __new__( place, transitions: net.t_tt( transitions ) )
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

  def initialize place, transitions: net.tt
    @place = net.place( place )
    @transitions = net.transitions( transitions )
  end

  # Extracts the value of this feature from the supplied target
  # (eg. a simulation).
  # 
  def extract_from arg, **nn
    # **nn is here because of timed / timeless possibility, where
    # **nn would contain :step named argument.
    case arg
    when YPetri::Simulation then
      if timed? then
        tt = arg.send( :T_transitions, transitions )
        -> Δt { tt.delta( Δt ).fetch( place ) }
      else
        arg.send( :t_transitions, transitions ).delta.fetch( place )
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

  def to_s
    place.name
  end

  def label
    "∂:#{place.name}:#{transitions.size}tt"
  end
end # class YPetri::Net::State::Feature::Delta
