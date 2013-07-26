class YPetri::Net::State
  class Feature
    # Gradient of a Petri net place caused by a certain set of T transitions.
    # 
    class Gradient < Feature
      attr_reader :place, :transitions

      class << self
        def parametrize *args
          Class.instance_method( :parametrize ).bind( self ).( *args )
        end

        def of place_id, transitions: []
          new place_id, transitions
        end
      end

      def initialize place, transitions
        @place = net.place place_id
        @transitions = transitions.map { |t_id| net.transition t_id }
      end

      def extract_from arg, **nn
        arg.gradient( place, transitions: transitions )
      end

      def to_s
        place.name
      end
    end # class Gradient
  end # class Feature
end # YPetri::Net::State
