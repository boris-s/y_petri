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
          new( features.zip( values ).map { |feat, val| feat.load val } )
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
        features.each { |f| fetch( f ).round( precision ) }
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
        State.new self, marking_clamps: marking_clamps
      end

      delegate :reconstruct, to: :state
    end # class Record
  end # class Features
end # YPetri::Net::State
