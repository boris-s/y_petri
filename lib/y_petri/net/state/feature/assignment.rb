# encoding: utf-8

# Firing of a Petri net A transition.
# 
class YPetri::Net::State::Feature::Assignment < YPetri::Net::State::Feature
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
                                           ç.net.A_transitions( [ id ] ).first
                                         rescue TypeError => err
                                           msg = "Transition #{id} not " +
                                             "recognized as A transition in " +
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
    def of id
      new id
    end
  end

  # The constructor of a marking feature takes exactly one argument (transition
  # identifier).
  # 
  def initialize transition
    @transition = net.transition( transition )
  end

  # Extracts the receiver marking feature from the argument. This can be
  # typically a simulation instance.
  # 
  def extract_from arg, **nn
    case arg
    when YPetri::Simulation then
      arg.send( :A_transitions, [ transition ] ).first.firing
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
    "A:#{transition.name}"
  end

  # Inspect string of the firing feature.
  # 
  def inspect
    "<Feature::Assignment of #{transition.name ? transition.name : transition}>"
  end
end # YPetri::Net::State::Feature::Assignment