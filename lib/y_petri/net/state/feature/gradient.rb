# encoding: utf-8

# Gradient of a Petri net place caused by a certain set of T transitions.
# 
class YPetri::Net::State::Feature::Gradient < YPetri::Net::State::Feature
  attr_reader :place, :transitions

  class << self
    def parametrize *args
      Class.instance_method( :parametrize ).bind( self ).( *args ).tap do |ç|
        # First, prepare the hash of instances.
        hsh = Hash.new do |ꜧ, id|
          if id.is_a? self then
            ꜧ[ [ id.place, transitions: id.transitions.sort_by( &:object_id ) ] ]
          else
            p = id.fetch( 0 )
            tt = id
              .fetch( 1 )
              .fetch( :transitions )
            if p.is_a? ç.net.Place and tt.all? { |t| t.is_a? ç.net.Transition }
              tt_sorted = tt.sort_by &:object_id
              if tt == tt_sorted then
                tt = begin
                       ç.net.T_transitions( tt )
                     rescue TypeError => err
                       msg = "Transitions #{tt} not recognized as T " +
                         "transitions in net #{ç.net}! (%s)"
                       raise TypeError, msg % err
                     end
                ꜧ[ id ] = ç.__new__( *id )
              else
                ꜧ[ [ p, transitions: tt.sort_by( &:object_id ) ] ]
              end
            else
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

    def new *args
      return instances[ *args ] if args.size == 1
      instances[ args ]
    end

    def of *args
      new *args
    end
  end

  def initialize *id
    @place = net.place id.fetch( 0 )
    @transitions = net.transitions id.fetch( 1 ).fetch( :transitions )
  end

  def extract_from arg, **nn
    case arg
    when YPetri::Simulation then
      arg.send( :T_transitions, transitions ).gradient.fetch( place )
    else
      fail TypeError, "Argument type not supported!"
    end
  end

  def to_s
    place.name
  end

  def label
    "∂:#{place.name}:#{transitions.size}tt"
  end
end # class YPetri::Net::State::Feature::Gradient
