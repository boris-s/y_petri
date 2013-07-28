# encoding: utf-8

class YPetri::Net::State
  # A feature of a Petri net.
  #
  class Feature
    require_relative 'feature/marking'
    require_relative 'feature/firing'
    require_relative 'feature/gradient'
    require_relative 'feature/flux'
    require_relative 'feature/delta'

    class << self
      def parametrize **nn
        super.tap do |ç|
          ç.instance_variable_set :@Marking,
                                  Marking.parametrize( State: ç.State )
          ç.instance_variable_set :@Firing,
                                  Firing.parametrize( State: ç.State )
          ç.instance_variable_set :@Gradient,
                                  Gradient.parametrize( State: ç.State )
          ç.instance_variable_set :@Flux,
                                  Flux.parametrize( State: ç.State )
          ç.instance_variable_set :@Delta,
                                  Delta.parametrize( State: ç.State )
        end
      end

      delegate :net, to: "State()"

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

      def Gradient id=L!
        return @Gradient if id.local_object?
        case id
        when Gradient() then id
        when Gradient then
          Gradient().of( id.place, transitions: id.transitions )
        else Gradient().of( id ) end # assume it's a place
      end

      def Flux id=L!
        return @Flux if id.local_object?
        case id
        when Flux() then id
        when Flux then Flux().of( id.transition )
        else Flux().of( id ) end # assume it's a place
      end

      def Delta id=L!
        return @Delta if id.local_object?
        case id
        when Delta() then id
        when Delta then
          Delta().of( id.place, transitions: id.transitions )
        else Delta().of( id ) end # assume it's a place
      end
    end # class << self

    delegate :net,
             :State,
             :Marking, :Firing, :Gradient, :Flux, :Delta,
             to: :class
  end # class Feature
end # YPetri::Net::State
