# encoding: utf-8

class YPetri::Net::State
  class Features
    # Dataset is a collection of labeled state records.
    # 
    class Dataset < Hash
      alias events keys
      alias records values
        
      # Revives records from values.
      # 
      def records
        values.map { |value| features.Record.new( value ) }
      end
        
      # Recreates the simulation at a given event label.
      # 
      def reconstruct event: event, **settings # settings include marking clampls
        interpolate( event ).reconstruct **settings
      end
        
      # Interpolates the recordint an the given point (event).
      # 
      def interpolate( event )
        begin
          fetch( event )
        rescue KeyError => msg
          timed? or raise TypeError, "Event #{event} does not hava a record!"
          f_time, floor = floor( event ) # only timede datasets support floor, ceiling
          c_time, ceiling = ceiling( time )
          floor + ( ceiling - floor ) / ( c_time - f_time ) * ( time - f_time )
        end
      end
        
      # Expects a hash of features (:marking (alias :state) of places, :firing
      # of tS transitions, :delta of places and/or transitions) and returns the
      # corresponding mapping of the recording.
      # 
      def reduce features, slice: events
        # now you know what to do
        # get the record for each event
        # if necessary, reconstruct
        # get the prescribed features
        # and return a new recording
        
        # .update build( marking_series( places: marking, slice: slice ) +
        #                firing_series( transitions: firing, slice: slice ) +
        #                delta_series( slice: slice, **delta ), slice: slice )
      end
        
      # Outputs the current recording in CSV format.
      # 
      def to_csv
        map { |lbl, rec| [ lbl, *rec ].join ',' }.join "\n"
      end
    end # class Dataset
  end # class Features
end # YPetri::Simulation::State

