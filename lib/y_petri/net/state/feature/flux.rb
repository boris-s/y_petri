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

      def initialize transition_id
        @transition = net.transition transition_id
      end

      def extract_from arg, **nn
        arg.flux( transition )
      end
    end # class Flux
  end # class Feature
end # YPetri::Net::State
