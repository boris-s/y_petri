# encoding: utf-8

# A feature of a Petri net.
#
class YPetri::Net::State::Feature
  require_relative 'feature/marking'
  require_relative 'feature/firing'
  require_relative 'feature/gradient'
  require_relative 'feature/flux'
  require_relative 'feature/delta'

  class << self
    def parametrize parameters
      Class.new( self ).tap do |ç|
        parameters.each_pair do |ß, val|
          ç.define_singleton_method ß do val end
        end
        sç = ç.State
        ç.instance_variable_set :@Marking, Marking.parametrize( State: sç )
        ç.instance_variable_set :@Firing, Firing.parametrize( State: sç )
        ç.instance_variable_set :@Gradient, Gradient.parametrize( State: sç )
        ç.instance_variable_set :@Flux, Flux.parametrize( State: sç )
        ç.instance_variable_set :@Delta, Delta.parametrize( State: sç )
      end
    end

    delegate :net,
             to: "State()"

    def Marking id=L!
      return @Marking if id.local_object?
      case id
      when Marking() then id
      when Marking then Marking().of( id.place )
      else Marking().of( id ) end # assume it's a place
    end

    def Firing id=L!
      return @Firing if id.local_object?
      case id
      when Firing() then id
      when Firing then Firing().of( id.transition )
      else Firing().of( id ) end # assume it's a place
    end

    def Gradient id=L!, transitions: net.T_tt
      return @Gradient if id.local_object?
      case id
      when Gradient() then id
      when Gradient then
        Gradient().of( id.place, transitions: id.transitions )
      else
        Gradient().of( id, transitions: transitions )
      end # assume it's a place
    end

    def Flux id=L!
      return @Flux if id.local_object?
      case id
      when Flux() then id
      when Flux then Flux().of( id.transition )
      else
        Flux().of( id )
      end # assume it's a place
    end

    def Delta id=L!, transitions: net.tt
      return @Delta if id.local_object?
      case id
      when Delta() then id
      when Delta then
        Delta().of( id.place, transitions: id.transitions )
      else Delta().of( id, transitions: transitions ) end # assume it's a place
    end
  end # class << self

  delegate :net,
           :State,
           :Marking, :Firing, :Gradient, :Flux, :Delta,
           to: "self.class"
end # class YPetri::Net::State::Feature
