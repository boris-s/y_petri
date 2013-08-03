# encoding: utf-8

# Marking of a Petri net place.
# 
class YPetri::Net::State::Feature::Marking < YPetri::Net::State::Feature
  attr_reader :place

  class << self
    def parametrize *args
      Class.instance_method( :parametrize ).bind( self ).( *args ).tap do |ç|
        ç.instance_variable_set( :@instances,
                                 Hash.new do |hsh, id|
                                   case id
                                   when self then
                                     hsh[ id.place ]
                                   when ç.net.Place then
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

    def of id
      new id
    end
  end

  def initialize place
    @place = net.place( place )
  end

  def extract_from arg, **nn
    case arg
    when YPetri::Simulation then
      arg.m( [ place ] ).first
    else
      fail TypeError, "Argument type not supported!"
    end
  end

  def to_s
    place.name
  end

  def label
    ":#{place.name}"
  end
end # YPetri::Net::State::Feature::Marking
