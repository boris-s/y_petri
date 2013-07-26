class YPetri::Net
  class State
    class Features
      # A collection of values for a given set of state features.
      # 
      class Record < Array
        class << self
          # Construcs a new Record object from a given collection of values.
          # 
          def load values
            new( features.zip( values ).map { |feat, val| feat.load val } )
          end
        end

        delegate :Features,
                 :features,
                 to: :class

        delegate :State,
                 :net,
                 to: :Features

        def dump precision: nil
          features.each { |f| self[ f ] }
        end

        def fetch feature
          super begin
                  Integer( feature )
                rescue TypeError
                  features.index State.feature( feature )
                end
        end

        def reconstruct **settings
          # FIXME - Reconstruct the simulation
        end
      end # class Record
    end # class Features
  end # class State
end # YPetri::Net
