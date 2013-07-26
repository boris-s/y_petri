class YPetri::Net
  class State
    # A set of state features.
    # 
    class Features < Array
      require_relative 'features/record'

      class << self
        alias __new__ new

        def new feature_collection
          __new__( feature_collection ).tap do |inst|
            inst.param_class( { Record: Record, Dataset: Dataset },
                              with: { Features: self, features: inst } )
          end
        end

        def marking places: net.pp
          new net.pp( places ).map { |p| net.Marking.of p }
        end

        def firing transitions: net.tS_tt
          new net.tS_tt( transitions ).map { |t| net.Firing.of t }
        end

        def gradient places: net.pp, transitions: net.T_tt
          tt = net.T_tt( transitions )
          new net.pp( places ).map { |p| net.Gradient.of p, transitions: tt }
        end

        def flux transitions: net.TS_tt
          new net.TS_tt( transitions ).map { |t| net.Flux.of t }
        end

        def delta places: net.pp, transitions: net.tt
          tt = net.tt( transitions )
          new net.pp( places ).map { |p| net.Delta.of p, transitions: tt }
        end
      end

      # Parametrized subclass:
      attr_reader :Record

      delegate :load, to: :Record
      
      # Initializes the feature set.
      # 
      def initialize marking: [],
        firing: [],
        delta: { places: [], transitions: [] }
        @marking = marking.map { |place| Feature::Marking.new place }
        @firing = firing.map { |transition| Feature::Firing.new transition }
        dpp, dtt = delta[:places], delta[:transitions]
        @delta = dpp.map { |p| Feature::Delta.new p, dtt }
      end
      
      # Extracts the features from a given target
      # 
      def extract_from target, **nn
        Record().new( map { |feature| feature.extract_from( target, **nn ) } )
      end
    end # class Features
  end # class State
end # YPetri::Net
