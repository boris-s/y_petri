class YPetri::Net::State
  class Feature
    # Firing of a Petri net tS transition.
    # 
    class Firing < Feature
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
        arg.firing( transition )
      end
    end # class Firing
  end # class Feature
end # YPetri::Net::State
