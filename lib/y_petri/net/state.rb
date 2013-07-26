# encoding: utf-8

class YPetri::Net
  # Petri net state (marking of all its places).
  #
  class State < Array
    require_relative 'state/feature'
    require_relative 'state/features'

    class << self
      def parametrize net: (fail ArgumentError, "No owning net!")
        super.tap do |ç|
          ç.param_class( { Feature: Feature }, with: { State: self } )
          ç.param_class( { Features: Features }, with: { State: self } )
        end
      end
    end

    # For non-parametrized vesion of the class, the class instance variables
    # hold the non-parametrized dependent classes.
    # 
    @Feature, @Features = Feature, Features

    delegate :net,
             :Feature,
             :Features,
             to: :class

    def reconstruct( event: nil, time: nil, marking_clamps: [], **nn )
      # FIXME
      net.new_simulation( marking: self,
                          marking_clamps: marking_clamps,
                          time: time,
                          **nn )
    end
  end # class State
end # YPetri::Net
