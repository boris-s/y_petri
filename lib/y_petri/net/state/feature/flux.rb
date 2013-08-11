# encoding: utf-8

# Flux of a Petri net TS transition.
# 
class YPetri::Net::State::Feature::Flux < YPetri::Net::State::Feature
  attr_reader :transition

  class << self
    def parametrize *args
      Class.instance_method( :parametrize ).bind( self ).( *args ).tap do |ç|
        ç.instance_variable_set( :@instances,
                                 Hash.new do |hsh, id|
                                   case id
                                   when self then
                                     hsh[ id.transition ]
                                   when ç.net.Transition then
                                     t = begin
                                           ç.net.TS_transitions( [ id ] ).first
                                         rescue TypeError => err
                                           msg = "Transition #{id} not " +
                                             "recognized as TS transition in " +
                                             "net #{ç.net}! (%s)"
                                           raise TypeError, msg % err
                                         end
                                     hsh[ id ] = ç.__new__( t )
                                   else
                                     hsh[ ç.net.transition( id ) ]
                                   end
                                 end )
      end
    end

    attr_reader :instances

    alias __new__ new

    def new id
      instances[ id ]
    end

    def of transition_id
      new transition_id
    end
  end

  def initialize id
    @transition = net.transition( id.is_a?( Flux ) ? id.transition : id )
  end

  def extract_from arg, **nn
    case arg
    when YPetri::Simulation then
      arg.send( :TS_transitions, [ transition ] ).first.flux
    else
      fail TypeError, "Argument type not supported!"
    end
  end

  def label
    "Φ:#{transition.name}"
  end
end # class YPetri::Net::State::Feature::Flux
