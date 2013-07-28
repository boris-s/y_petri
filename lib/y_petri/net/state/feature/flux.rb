class YPetri::Net::State
  class Feature
    # Flux of a Petri net TS transition.
    # 
    class Flux < Feature
      attr_reader :transition

      class << self
        def parametrize *args
          Class.instance_method( :parametrize ).bind( self ).( *args )
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
          arg.send( :TS_transitions, [ transition ] ).flux.first
        else
          fail TypeError, "Argument type not supported!"
        end
      end
    end # class Flux
  end # class Feature
end # YPetri::Net::State
