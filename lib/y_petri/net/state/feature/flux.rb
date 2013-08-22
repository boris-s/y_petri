# encoding: utf-8

# Flux of a Petri net TS transition.
# 
class YPetri::Net::State::Feature::Flux < YPetri::Net::State::Feature
  attr_reader :transition

  class << self
    # Customization of the Class#parametrize method.
    # 
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

    # Alias of #new method.
    # 
    def of transition_id
      new transition_id
    end
  end

  # The constructor of a marking feature takes exactly one argument (transition
  # identifier).
  # 
  def initialize id
    @transition = net.transition id.is_a?( Flux ) ? id.transition : id
  end

  # Extracts the receiver marking feature from the argument. This can be
  # typically a simulation instance.
  # 
  def extract_from arg, **nn
    case arg
    when YPetri::Simulation then
      arg.send( :TS_transitions, [ transition ] ).first.flux
    else
      fail TypeError, "Argument type not supported!"
    end
  end

  # Type of this feature.
  # 
  def type
    :flux
  end

  # A string briefly describing the flux feature.
  # 
  def to_s
    label
  end

  # Label for the flux feature (to use in the graphics etc.)
  # 
  def label
    "Φ:#{transition.name}"
  end

  # Inspect string of the flux feature.
  # 
  def inspect
    "<Feature::Flux of #{transition}>"
  end
end # class YPetri::Net::State::Feature::Flux
