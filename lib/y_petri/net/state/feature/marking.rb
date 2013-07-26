class YPetri::Net::State
  class Feature
    # Marking of a Petri net place.
    # 
    class Marking < Feature
      attr_reader :place

      class << self
        def parametrize *args
          Class.instance_method( :parametrize ).bind( self ).( *args )
        end

        def of place_id
          new place_id
        end
      end

      def initialize place_id
        @place = net.place place_id
      end

      def extract_from arg, **nn
        arg.marking( place )
      end

      def to_s
        place.name
      end
    end # class Marking
  end # class Feature
end # YPetri::Net::State
