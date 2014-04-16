# encoding: utf-8

# Marking of a Petri net place.
# 
class YPetri::Net::State::Feature::Marking < YPetri::Net::State::Feature
  attr_reader :place

  class << self
    # Customization of the Class#parametrize method.
    # 
    def parametrize *args
      Class.instance_method( :parametrize ).bind( self ).( *args ).tap do |ç|
        ç.instance_variable_set( :@instances,
                                 Hash.new do |hsh, id|
                                   case id
                                   when self then
                                     hsh[ id.place ]
                                   when ç.net.Place then
                                     p = begin
                                           ç.net.place id
                                         rescue TypeError => err
                                           raise TypeError, "Place #{id} not " +
                                             "present in net #{ç.net}! (#{err})"
                                         end
                                     hsh[ id ] = ç.__new__( id )
                                   else
                                     hsh[ ç.net.place( id ) ]
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

  # The constructor of a marking feature takes exactly one argument (place
  # identifier).
  # 
  def initialize place
    @place = net.place( place )
  end

  # Extracts the receiver marking feature from the argument. This can be
  # typically a simulation instance.
  # 
  def extract_from arg, **nn
    case arg
    when YPetri::Simulation then
      arg.m( place ).first
    else
      fail TypeError, "Argument type not supported!"
    end
  end

  # Type of this feature.
  # 
  def type
    :marking
  end

  # A string briefly describing the marking feature.
  # 
  def to_s
    "m:#{label}"
  end

  # Label for the marking feature (to use in graphics etc.)
  # 
  def label
    ":#{place.name}"
  end

  # Inspect string of the marking feature.
  # 
  def inspect
    "<Feature::Marking of #{place.name ? place.name : place}>"
  end

  # Marking features are equal if they are of equal PS and refer
  # to the same place.
  # 
  def == other
    other.is_a? net.State.Feature.Marking and place == other.place
  end
end # YPetri::Net::State::Feature::Marking
