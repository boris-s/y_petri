class YPetri::Net::State
  class Features
    # A collection of values for a given set of state features.
    # 
    class Record < Array
      class << self
        delegate :State,
                 :net,
                 to: "Features()"

        # Construcs a new Record object from a given collection of values.
        # 
        def load values
          new( values.dup )
        end
      end

      delegate :Features,
               :State,
               :net,
               :features,
               to: "self.class"

      # Outputs the record as a plain array.
      # 
      def dump precision: nil
        features.map { |f| fetch( f ).round( precision ) }
      end

      # Returns an identified feature, or fails.
      # 
      def fetch feature
        super begin
                Integer( feature )
              rescue TypeError
                features.index State().feature( feature )
              end
      end

      # Returns the state instance implied by the receiver record, and a set of
      # complementary marking clamps supplied as the argument.
      # 
      def state marking_clamps: {}
        State().new self, marking_clamps: marking_clamps
      end

      # Given a set of marking clamps complementary...
      # 
      def reconstruct marking_clamps: {}, **settings
        net.simulation marking_clamps: {}, marking: markings, **settings
      end

      # Returns the marking of a given place (must be in the record).
      # 
      def marking place_id
        fetch net.State.feature( marking: place_id )
      end

      # Returns the array of markings of given places (must be in the record).
      # 
      def markings place_ids
        place_ids.map &:marking
      end

      # Returns the flux of a given transition (must be in the record).
      # 
      def flux transition_id
        fetch net.State.feature( flux: transition_id )
      end

      # Returns the array of fluxes of given transitions (must be in the record).
      #
      def fluxes transition_ids
        transition_ids.map &:flux
      end

      # Returns the firing of a given transition (must be in the record).
      # 
      def firing transition_id
        fetch net.State.feature( firing: transition_id )
      end

      # Returns the firings of given transitions (must be in the record).
      # 
      def firings transition_ids
        transition_ids.map &:firing
      end

      # Returns the gradient of a given place, contributed by a given set of
      # transitions (the feature must be in the record).
      # 
      def gradient place_id, transitions: transition_ids
        fetch net.State
          .feature( gradient: [ place_id, transitions: transition_ids ] )
      end

      # Returns the gradients of given places, contributed by a given set of
      # transitions (the features must be in the record).
      # 
      def gradients place_ids, transitions: transition_ids
        place_ids.map { |id| gradient id, transitions: transition_ids }
      end

      # Returns the delta of a given place, contributed by a given set of
      # transitions (the feature must be in the record).
      # 
      def delta place_id, transitions: transition_ids
        fetch net.State
          .feature( delta: [ place_id, transitions: transition_ids ] )
      end

      # Returns the deltas of given places, contributed by a given set of
      # transitions (the features must be in the record).
      # 
      def deltas place_ids, transitions: transition_ids
        place_ids.map { |id| delta id, transitions: transition_ids }
      end
    end # class Record
  end # class Features
end # YPetri::Net::State
