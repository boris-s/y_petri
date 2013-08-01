# encoding: utf-8

class YPetri::Net::State
  class Features
    # Dataset is a collection of labeled state records.
    # 
    class Dataset < Hash
      class << self
        alias __new__ new

        def new
          __new__ do |hsh, missing|
            case missing
            when Float then nil
            else hsh[ missing.to_f ] end
          end
        end
      end

      alias events keys
      alias records values

      delegate :features, to: "self.class"
      delegate :net, to: :features
      delegate :State, to: :net

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
          timed? or raise TypeError, "Event #{event} does not have a record!"
          f_time, floor = floor( event ) # timed datasets support floor, ceiling
          c_time, ceiling = ceiling( time )
          floor + ( ceiling - floor ) / ( c_time - f_time ) * ( time - f_time )
        end
      end

      # Returns the data series for the specified features.
      # 
      def series arg=nil
        return records.transpose if arg.nil?
        reduce_features( State().features( arg ) ).series
      end

      # Expects a hash of features (:marking (alias :state) of places, :firing
      # of tS transitions, :delta of places and/or transitions) and returns the
      # corresponding mapping of the recording.
      # 
      def reduce_features features
        rf = net.State.features( features )
        rr_class = rf.Record
        rf.new_dataset.tap do |ds|
        ( events >> records ).each_pair { |event, record|
            ds.update event => rr_class.load( rf.map { |f| record.fetch f } )
          }
        end
      end

      def marking *args
        return reduce_features features.select { |f| f.is_a? YPetri::Net::State::Feature::Marking } if args.empty?
        reduce_features marking: args.first
      end

      def firing *args
        return reduce_features features.select { |f| f.is_a? YPetri::Net::State::Feature::Firing } if args.empty?
        reduce_features firing: args.first
      end

      def flux *args
        return reduce_features features.select { |f| f.is_a? YPetri::Net::State::Feature::Flux } if args.empty?
        reduce_features flux: args.first
      end

      def gradient *args
        return reduce_features features.select { |f| f.is_a? YPetri::Net::State::Feature::Gradient } if args.empty?
        reduce_features gradient: args
      end

      def delta *args
        return reduce_features features.select { |f| f.is_a? YPetri::Net::State::Feature::Delta } if args.empty?
        reduce_features delta: args
      end

      # Outputs the current recording in CSV format.
      # 
      def to_csv
        map { |lbl, rec| [ lbl, *rec ].join ',' }.join "\n"
      end

      # Plots the dataset.
      # 
      def plot time: nil, **nn
        events = events()
        data_ss = series
        x_range = if time.is_a? Range then
                    "[#{time.begin}:#{time.end}]"
                  else
                    "[-0:#{SY::Time.magnitude( time ).amount rescue time}]"
                  end
        
        Gnuplot.open do |gp|
          Gnuplot::Plot.new gp do |plot|
            plot.xrange x_range
            plot.title nn[:title] || "#{net} plot"
            plot.ylabel nn[:ylabel] || "Values"
            plot.xlabel nn[:xlabel] || "Time [s]"

            features.labels.zip( data_ss )
              .each { |label, data_array|
              plot.data << Gnuplot::DataSet.new( [ events, data_array ] ) { |ds|
                ds.with = "linespoints"
                ds.title = label
              }
            }
          end
        end
      end
    end # class Dataset
  end # class Features
end # YPetri::Simulation::State
