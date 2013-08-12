# encoding: utf-8

# Dataset is a collection of labeled state records.
# 
class YPetri::Net::DataSet < Hash
  class << self
    alias __new__ new

    def new type: nil
      __new__ do |hsh, missing|
        case missing
        when Float then nil
        else hsh[ missing.to_f ] end
      end.tap { |inst|
        inst.instance_variable_set :@type, type
      }
    end

    private :__new__

    delegate :net, to: :features
    delegate :State, to: :net
    delegate :Marking, :Firing, :Flux, :Gradient, :Delta,
             to: "State()"
  end

  alias events keys
  alias records values

  delegate :features,
           :net,
           :State,
           :Marking, :Firing, :Flux, :Gradient, :Delta,
           to: "self.class"

  attr_reader :type # more like event_type, idea not matured yet

  # Type of the dataset.
  # 
  def timed?
    type == :timed
  end

  # Returns a Record instance corresponding to the given recorded event.
  # 
  def record( event )
    features.load( fetch event )
  end

  # Revives records from values.
  # 
  def records
    values.map { |value| features.Record.new( value ) }
  end

  # Recreates the simulation at a given event label.
  # 
  def reconstruct event: (fail "No event given!"),
    **settings # settings include marking clamps
    rec = interpolate( event )
    if timed? then
      rec.reconstruct time: event, **settings
    else
      rec.reconstruct **settings
    end
  end

  # Interpolates the recording an the given point (event). Return value is the
  # Record class instance.
  # 
  def interpolate( event )
    # TODO: This whole interpolation thing is unfinished.
    begin
      record( event )
    rescue KeyError => msg
      timed? or raise TypeError, "Event #{event} does not have a record! (%s)" %
        "simulation type: #{type.nil? ? 'nil' : type}"
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
  def reduce_features *args
    Δt = if args.last.is_a? Hash then
           args.last.may_have( :delta_time, syn!: :Δt )
           args.last.delete( :delta_time )
             .tap { args.delete_at( -1 ) if args.last.empty? }
         end
    reduced_features = net.State.features *args
    rf_Record = reduced_features.Record
    reduced_features.new_dataset( type: type ).tap do |dataset|
      ( events >> records ).each_pair do |event, record|
        absent_features = reduced_features - features()
        if absent_features.empty? then # it is a subset
          line = reduced_features.map { |feature| record.fetch feature }
        else # it will require simulation reconstruction
          sim = reconstruct event: event
          if absent_features.any? { |f| f.timed? rescue false } then
            fail ArgumentError, "Reconstruction of timed features requires " +
              "the named arg :delta_time to be given!" unless Δt
            line = reduced_features.map do |feature|
              if absent_features.include? feature then
                if ( feature.timed? rescue false ) then
                  feature.extract_from( sim ).( Δt )
                else
                  feature.extract_from( sim )
                end
              else
                record.fetch feature
              end
            end
          else
            line = reduced_features.map do |feature|
              if absent_features.include? feature then
                feature.extract_from( sim )
              else
                record.fetch feature
              end
            end
          end
        end
        dataset.update event => rf_Record.load( line )
      end
    end
  end

  # Returns a subset of this dataset with only the specified marking features
  # identified by the arguments retained. If no arguments are given, all the
  # marking features from the receiver dataset are selected.
  # 
  def marking ids=nil
    return reduce_features net.State.marking if ids.nil?
    reduce_features marking: ids
  end

  # Returns a subset of this dataset with only the specified firing features
  # identified by the arguments retained. If no arguments are given, all the
  # firing features from the receiver dataset are selected.
  # 
  def firing *args
    Δt = if args.last.is_a? Hash then
           args.last.may_have( :delta_time, syn!: :Δt )
           args.last.delete( :delta_time )
             .tap { args.delete_at( -1 ) if args.last.empty? }
         end
    if Δt then
      return reduce_features net.State.firing, delta_time: Δt if args.empty?
      reduce_features firing: args.first, delta_time: Δt
    else
      return reduce_features net.State.firing if args.empty?
      reduce_features firing: args.first
    end
  end

  # Returns a subset of this dataset with only the specified flux features
  # identified by the arguments retained. If no arguments are given, all the
  # flux features from the receiver dataset are selected.
  # 
  def flux ids=nil
    return reduce_features net.State.flux if ids.nil?
    reduce_features flux: ids
  end

  # Returns a subset of this dataset with only the specified gradient features
  # identified by the arguments retained. If no arguments are given, all the
  # gradient features from the receiver dataset are selected.
  # 
  def gradient *args
    return reduce_features net.State.gradient if args.empty?
    reduce_features gradient: args
  end

  # Returns a subset of this dataset with only the specified delta features
  # identified by the arguments retained. If no arguments are given, all the
  # delta features from the receiver dataset are selected.
  # 
  def delta *args
    Δt = if args.last.is_a? Hash then
           args.last.may_have( :delta_time, syn!: :Δt )
           args.last.delete( :delta_time )
             .tap { args.delete_at( -1 ) if args.last.empty? }
         end
    if Δt then
      return reduce_features net.State.delta, delta_time: Δt if args.empty?
      reduce_features delta: args, delta_time: Δt
    else
      return reduce_features net.State.delta if args.empty?
      reduce_features delta: args
    end
  end

  # Outputs the current recording in CSV format.
  # 
  def to_csv
    map { |lbl, rec| [ lbl, *rec ].join ',' }.join "\n"
  end

  # Plots the dataset.
  # 
  def plot( time: nil, **nn )
    events = events()
    data_ss = series
    x_range = if time.nil? then
                "[#{events.first}:#{events.last}]"
              elsif time.is_a? Range then
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
        features.labels.zip( data_ss ).each do |label, data_array|
          plot.data << Gnuplot::DataSet.new( [ events, data_array ] ) { |ds|
            ds.with = "linespoints"
            ds.title = label
          }
        end
      end
    end
  end
end # YPetri::Net::Dataset
