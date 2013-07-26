class YPetri::Net::State
  class Feature
    # Change of a Petri net place caused by a certain set of transitions.
    # 
    class Delta < Feature
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
        # **nn is here because of timed / timeless possibility, where
        # **nn would contain :step named argument.
        arg.delta( place, transitions: transitions, **nn )
      end

      def to_s
        place.name
      end
    end # class Delta
  end # class Feature
end # YPetri::Net::State
