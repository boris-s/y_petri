# encoding: utf-8

# Firing of a Petri net tS transition.
# 
class YPetri::Net::State::Feature::Firing < YPetri::Net::State::Feature
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
                                           ç.net.tS_transitions( [ id ] ).first
                                         rescue TypeError => err
                                           msg = "Transition #{id} not " +
                                             "recognized as tS transition in " +
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

    def of id
      new id
    end
  end

  def initialize transition
    @transition = net.transition( transition )
  end

  def extract_from arg, **nn
    case arg
    when YPetri::Simulation then
      arg.send( :tS_transitions, [ transition ] ).first.firing
    else
      fail TypeError, "Argument type not supported!"
    end
  end

  def label
    "F:#{transition.name}"
  end
end # YPetri::Net::State::Feature::Firing
