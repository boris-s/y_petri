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
        state_class = nn[:State] or fail ArgumentError, "No owning net state!"
        super.tap do |ç|
          ç.param_class( { Marking: Marking }, with: { State: state_class } )
          ç.param_class( { Firing: Firing }, with: { State: state_class } )
          ç.param_class( { Gradient: Gradient }, with: { State: state_class } )
          ç.param_class( { Flux: Flux }, with: { State: state_class } )
          ç.param_class( { Delta: Delta }, with: { State: state_class } )
        end
      end
    end # class << self

    delegate :net,
             :State,
             :Marking, :Firing, :Gradient, :Flux, :Delta,
             to: :class
  end # class Feature
end # YPetri::Net::State
