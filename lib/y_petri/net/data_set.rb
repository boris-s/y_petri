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
    delegate :Marking, :Firing, :Flux, :Gradient, :Delta, :Assignment,
             to: "State()"
  end

  alias events keys
  alias records values

  delegate :features,
           :net,
           :State,
           :Marking, :Firing, :Flux, :Gradient, :Delta, :Assignment,
           to: "self.class"

  attr_reader :type, # more like event_type, idea not matured yet
              :settings

  # Type of the dataset.
  # 
  def timed?
    type == :timed
  end

  # Returns the Record instance corresponding to the given recorded event.
  # 
  def record( event )
    features.load( fetch event )
  end

  # Returns the nearest event smaller or equal to the supplied event-type
  # argument. The second optional ordered argument, true by default, controls
  # whether equality is accepted. If set to false, then the nearest _smaller_
  # event is sought.
  # 
  def floor( event, equal_ok=true )
    e = events.ascending_floor( event, equal_ok )
    e.nil? ? nil : e
  end

  # Returns the nearest event greater or equal to the supplied event-type
  # argument. The second optional ordered argument, true by default, controls
  # whether equality is accepted. If set to false, then the nearest _greater_
  # event is sought.
  # 
  def ceiling( event, equal_ok=true )
    e = events.ascending_ceiling( event, equal_ok )
    e.nil? ? nil : e
  end

  # Revives records from values.
  # 
  def records
    values.map { |value| features.Record.new( value ) }
  end

  # Recreates the simulation at a given event label.
  # 
  def reconstruct at: (fail "No event given!"), **settings
    # settings may include marking clamps, marking, inital marking...
    rec = interpolate( at )
    settings = settings().merge settings if settings()
    if timed? then
      rec.reconstruct time: at, **settings
    else
      rec.reconstruct **settings
    end
  end

  # Interpolates the recording an the given point (event). Return value is the
  # Record class instance.
  # 
  def interpolate( event )
    begin
      record( event )
    rescue KeyError => msg
      timed? or raise TypeError, "Event #{event} not recorded! (%s)" %
        "simulation type: #{type.nil? ? 'nil' : type}"
      # (Remark: #floor, #ceiling supported by timed datasets only)
      fe = floor( event )
      fail "Event #{event} has no floor!" if fe.nil?
      f = Matrix.column_vector record( fe )
      ce = ceiling( event )
      fail "Event #{event} has no ceiling!" if ce.nil?
      c = Matrix.column_vector record( ce )
      rslt = f + ( c - f ) / ( ce - fe ) * ( event - fe )
      features.load( rslt.column_to_a )
    end
  end

  # Resamples the recording.
  # 
  def resample **nn
    time_range = nn.may_have( :time_range, syn!: :time ) ||
      events.first .. events.last
    sampling = nn.must_have :sampling
    t0, target_time = time_range.begin, time_range.end
    t = t0
    o = self.class.new type: type
    loop do
      o.update t => interpolate( t )
      t += sampling
      return o if t > target_time
    end
  end

  # Computes the distance to another dataset.
  # 
  def distance( other )
    sum_of_sq = events
      .map { |e| [ e, other.interpolate( e ) ] }
      .map { |rec1, rec2| rec1.euclidean_distance rec2 }
      .map { |dist| dist * dist }
      .reduce( :+ )
    sum_of_sq ** 0.5
  end

  # Returns the data series for the specified features.
  # 
  def series arg=nil
    return records.transpose if arg.nil?
    reduce_features( State().features( arg ) ).series
  end

  # Expects a hash of features (:marking (alias :state) of places, :firing
  # of tS transitions, :delta of places and/or transitions, :assignment of
  # A transitions) and returns the corresponding mapping of the recording.
  # 
  def reduce_features *args
    Δt = if args.last.is_a? Hash then
           args.last.may_have( :delta_time, syn!: :Δt )
           args.last.delete( :delta_time )
             .tap { args.delete_at( -1 ) if args.last.empty? }
         end
    reduced_features = net.State.features *args
    rf_Record = reduced_features.Record
    reduced_features.new_dataset( type: type ).tap { |dataset|
      ( events >> records ).each_pair { |event, record|
        absent_features = reduced_features - features()
        if absent_features.empty? then # it is a subset
          line = reduced_features.map { |feature| record.fetch feature }
        else # it will require simulation reconstruction
          sim = reconstruct at: event
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
            line = reduced_features.map do |feat|
              if absent_features.include? feat then
                feat.extract_from( sim )
              else record.fetch( feat ) end
            end
          end
        end
        dataset.update event => rf_Record.load( line )
      }
    }
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

  # Returns a subset of this dataset with only the specified assignment features
  # identified by the arguments retained. If no arguments are given, all the
  # assignment features from the receiver dataset are selected.
  # 
  def assignment *args
    return reduce_features net.State.assignment if args.empty?
      reduce_features assignment: args.first
    end
  end

  # Outputs the current recording in CSV format.
  # 
  def to_csv
    map { |lbl, rec| [ lbl, *rec ].join ',' }.join "\n"
  end

  # Plots the dataset. Takes several optional arguments: The list of elements
  # can be supplied as optional first ordered argument, which are then converted
  # into features using +Net::State::Features.infer_from_elements+ method.
  # Similarly, the features to exclude can be specifies as a list of elements
  # (or a feature-specifying hash) supplied under +except:+ keyword. Otherwise,
  # feature specification can be passed to the method as named arguments. If
  # no feature specification is explicitly provided, it is assumed that all the
  # features of this dataset are meant to be plotted.
  # 
  def plot( elements=nil, except: [], **named_args )
    nn = named_args
    time = nn.may_have :time, syn!: :time_range
    events = events()
    # Figure out features.
    ff = if elements.nil? then
           nn_ff = nn.slice [ :marking, :flux, :firing,
                              :gradient, :delta, :assignment ]
           nn_ff.empty? ? features : net.State.features( nn_ff )
         else
           net.State.Features.infer_from_elements( element_ids )
         end
    # Figure out the features not to plot ("except" features).
    xff = case except
          when Array then net.State.Features.infer_from_elements( except )
          when Hash then net.State.features( except )
          else
            fail TypeError, "Wrong type of :except argument: #{except.class}"
          end
    # Subtract the "except" features from features to plot.
    ff -= xff
    # Convert the feature set into a set of data arrays.
    data_arrays = series( ff )
    # Figure out the x axis range for plotting.
    x_range = if nn.has? :time then
                if time.is_a? Range then
                  "[#{time.begin}:#{time.end}]"
                else
                  "[-0:#{SY::Time.magnitude( time ).amount rescue time}]"
                end
              else
                from = events.first || 0
                to = if events.last and events.last > from then events.last
                     else events.first + 1 end
                "[#{from}:#{to}]"
              end
    # Invoke Gnuplot.
    Gnuplot.open do |gp|
      Gnuplot::Plot.new gp do |plot|
        plot.xrange x_range
        if nn.has? :yrange, syn!: :y_range then
          if nn[:yrange].is_a? Range then
            plot.yrange "[#{nn[:yrange].begin}:#{nn[:yrange].end}]"
          else fail TypeError, "Argument :yrange is not a range!" end
        end
        plot.title nn[:title] || "#{net} plot"
        plot.ylabel nn[:ylabel] || "Values"
        plot.xlabel nn[:xlabel] || "Time [s]"
        ff.labels.zip( data_arrays ).each do |label, array|
          # Replace NaN and Infinity with 0.0 and warn about it.
          nan, inf = 0, 0
          array = array.map { |v|
            if v.infinite? then inf += 1; 0.0
            elsif v.nan? then nan += 1; 0.0
            else v end
          }
          # Warn.
          nan = nan > 0 ? "#{nan} NaN values" : nil
          inf = inf > 0 ? "#{inf} infinite values" : nil
          msg = "Warning: column #{label} contains %s plotted as 0!"
          warn msg % [ nan, inf ].compact.join( ' and ' ) if nan or inf
          # Finally, plot.
          plot.data << Gnuplot::DataSet.new( [ events, array ] ) { |set|
            set.with = "linespoints"
            set.title = label
          }
        end
      end
    end
  end

  # Returns a string briefly discribing the dataset.
  # 
  def to_s
    "#<DataSet: " +
      "#{keys.size} records, " +
      "features: #{features}" +
      ">"
  end

  # Inspect string of the instance.
  # 
  def inspect
    to_s
  end

  # Pretty print the dataset. Takes +:precision+ and +:distance+ named arguments,
  # that control the shape of the printed table.
  # 
  def print precision: 4, distance: precision + 4
    features.labels.print_as_line precision: precision, distance: distance
    puts '-' * features.size * distance
    records.each { |record|
      record.print_as_line precision: precision, distance: distance
    }
    return nil
  end
end # YPetri::Net::Dataset
