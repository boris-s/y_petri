# encoding: utf-8

# +DataSet+ is a collection of labeled state records. It is a subclass of +Hash+
# class, whose keys are known as _events_, and values are data points (arrays)
# that correspond to saved records (+YPetri::Net::State::Features::Record+) under
# a given feature set (+YPetri::Net::State::Features+). +DataSet+ class is
# intended to be parametrized with a specific feature set. Apart from the methods
# inherited from +Hash+, +YPetri::Net::DataSet+ can load a record at a given
# event (+#record+ method), reconstruct a simulation at a given event
# (+#reconstruct+ method), return columns corresponding to features (+#series+
# method) and perform feature selection (+#marking+, +#firing+, +#flux+,
# +#gradient+, +#delta+, +#assignment+, and +#reduced_features+ for mixed feature
# sets). Apart from standard inspection methods, +DataSet+ has methods +#print+
# and +#plot+ for visual presentation. Also, +DataSet+ has methods specially
# geared towards records of timed simulations, whose events are points in time.
# Method +#interpolate+ uses linear interpolation to find the approximate state
# of the system at some exact time using linear interpolation between the nearest
# earlier and later data points (which can be accessed respectively by +#floor+
# and +#ceiling+ methods). Interpolation is used for resampling the set
# (+#resample+ method).
#
# Finally, it is possible that especially professional statisticians have
# written, or are planning to write, a +DataSet+ class better than this one.
# If I discover a good +DataSet+ class in the future, I would like to inherit
# from it or otherwise integrate with it for the purposes of
# +YPetri::Net::DataSet+.
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
  end

  alias events keys

  delegate :features,
           :net,
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
    record = interpolate( at )
    settings = settings().merge settings if settings()
    if timed? then
      record.reconstruct time: at, **settings
    else
      record.reconstruct **settings
    end
  end

  # Interpolates the recording at the given point (event). Return value is the
  # Record class instance.
  # 
  def interpolate( event )
    begin
      record( event )
    rescue KeyError => msg
      timed? or raise TypeError, "Event #{event} not recorded! (%s)" %
        "simulation type: #{type.nil? ? 'nil' : type}"
      # (Remark: #floor, #ceiling supported by timed datasets only)
      floor = floor( event )
      fail "Event #{event} has no floor!" if floor.nil?
      fl = Matrix.column_vector record( floor )
      ceiling = ceiling( event )
      fail "Event #{event} has no ceiling!" if ceiling.nil?
      ce = Matrix.column_vector record( ceiling )
      rslt = fl + ( ce - fl ) / ( ceiling - floor ) * ( event - floor )
      features.load( rslt.column_to_a )
    end
  end
  alias at interpolate

  # Resamples the recording.
  # 
  def resample **settings
    time_range = settings.may_have( :time_range, syn!: :time ) ||
      events.first .. events.last
    sampling = settings.must_have :sampling
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
  def series array=nil
    return records.transpose if array.nil?
    reduce_features( net.State.Features array ).series
  end

  # Expects a hash of features (:marking (alias :state) of places, :firing
  # of tS transitions, :delta of places and/or transitions, :assignment of
  # A transitions) and returns the corresponding mapping of the recording.
  # 
  def reduce_features array=nil, **named_args
    delta_time_given = named_args.has? :delta_time, syn!: :Δt
    Δt = named_args.delete :delta_time
    ff = net.State.Features[ *array, **named_args ] # reduced feature set
    absent = ff - features()         # features absent from the current set
    present = ff - absent            # features present in the current set
    timedness = true if absent.any? { |f| f.timed? rescue false }
    fail ArgumentError, "Reconstruction of timed features requires Δt to be" +
      "supplied!" unless delta_time_given if timedness
    present_ii =
      present.each_with_object( {} ) { |f, ꜧ| ꜧ[f] = features().index f }
    ds = ff.DataSet.new type: type
    if absent.empty? then # no reconstruction
      ( events >> records ).each_with_object ds do |(event, record), dataset|
        line = record.values_at *ff.map( &present_ii.method( :[] ) )
        dataset.update event => ff.load( line )
      end
    else
      ( events >> records ).each_with_object ds do |(event, record), dataset|
        reconstructed_sim = reconstruct at: event
        line = if timedness then
                 ff.map { |f|
                   i = present_ii[ f ]
                   break record[ i ] if i
                   f.extract_from( reconstructed_sim, Δt: Δt )
                 }
               else
                 ff.map { |f|
                   i = present_ii[ f ]
                   break record[ i ] if i
                   f.extract_from( reconstructed_sim, Δt: Δt )
                 }
               end
        dataset.update event => ff.load( line )
      end
    end
  end

  # Expects an array of marking feature identifiers, and returns a subset of
  # this dataset with only the specified marking features retained.
  # 
  def Marking array
    reduce_features marking: array
  end

  # Expects an arbitrary number of marking feature identifiers, and returns a
  # subset of this dataset with only the specified marking features retained.
  # If no arguments are given, all the marking features are assumed.
  # 
  def marking *ids
    return Marking net.State.Features.marking if ids.empty?
    Marking ids
  end

  # Expects an array of firing feature identifiers, and returns a subset of
  # this dataset with only the specified firing features retained. Named
  # arguments may include +:delta_time+, alias +:Δt+ (for firing of timed
  # transitions).
  # 
  def Firing array, **named_args
    reduce_features firing: array, **named_args
  end

  # Expects an arbitrary number of firing feature identifiers and returns
  # a subset of this dataset with only the specified firing features retained.
  # Named arguments may include +:delta_time+, alias +:Δt+ (for firing of
  # timed transitions).
  # 
  def firing *ids, **named_args
    return Firing net.State.Features.firing, **named_args if ids.empty?
    Firing ids, **named_args
  end

  # Expects an array of flux feature identifiers, and returns a subset of
  # this dataset with only the specified flux features retained.
  # 
  def Flux array
    reduce_features flux: array
  end

  # Expects an arbitrary number of flux feature identifiers, and returns
  # a subset of this dataset, with only the specified flux features retained.
  # If no aruments are given, full set of flux features is assumed.
  # 
  def flux *ids
    return Flux net.State.Features.flux if ids.empty?
    Flux ids
  end

  # Expects an array of gradient feature identifiers, optionally qualified by
  # the +:transitions+ named argument, defaulting to all T transitions in the
  # net.
  # 
  def Gradient array, transitions: nil
    if transitions.nil? then
      reduce_features gradient: array
    else
      reduce_features gradient: [ *array, transitions: transitions ]
    end
  end

  # Returns a subset of this dataset with only the specified gradient features
  # identified by the arguments retained. If no arguments are given, all the
  # gradient features from the receiver dataset are selected.
  # 
  def gradient *ids, transitions: nil
    return Gradient net.State.Features.gradient, transitions: transitions if
      ids.empty?
    Gradient ids, transitions: transitions
  end

  # Expects an array of delta feature identifiers, optionally qualified by
  # the +:transitions+ named argument, defaulting to all the transitions in
  # the net.
  # 
  def Delta array, transitions: nil, **named_args
    if named_args.has? :delta_time, syn!: :Δt then
      Δt = named_args.delete( :delta_time )
      if transitions.nil? then
        reduce_features delta: array, Δt: Δt
      else
        reduce_features delta: [ *array, transitions: transitions ], Δt: Δt
      end
    else
      if transitions.nil? then
        reduce_features delta: array
      else
        reduce_features delta: [ *array, transitions: transitions ]
      end
    end
  end

  # Expects an arbitrary number of ordered arguments identifying delta
  # features, optionally qualified by the +:transitions+ named argument,
  # defaulting to all the transitions in the net.
  # 
  def delta *ordered_args, transitions: nil, **named_args
    return Delta( ordered_args, transitions: transitions, **named_args ) unless
      ordered_args.empty?
    return Delta( net.places, **named_args ) if transitions.nil?
    Delta( net.places, transitions: transitions, **named_args )
  end

  # 
  def delta_timed *ordered_args, **named_args
    delta *ordered_args, transitions: net.T_transitions, **named_args
  end

  def delta_timeless *ordered_args, **named_args
    delta *ordered_args, transitions: net.t_transitions, **named_args
  end

  # Expects an array of assignment feature identifiers. Returns a subset of this
  # dataset with only the specified assignment features retained.
  # 
  def Assignment array
    reduce_features assignment: array
  end

  # Expects an arbitrary number of assignment feature identifiers as arguments,
  # and returns a subset of this dataset with only the specified assignment
  # features retained. If no arguments are given, all the assignment features
  # are assumed.
  # 
  def assignment *ids
    return reduce_features net.State.Features.assignment if args.empty?
    reduce_features assignment: ids
  end

  # Outputs the current recording in CSV format.
  # 
  def to_csv
    require 'csv'
    [ ":event", *features.labels.map( &:to_s ) ].join( ',' ) + "\n" +
      map { |lbl, rec| [ lbl, *rec ].join ',' }.join( "\n" )
  end

  # Plots the dataset. Takes several optional arguments: The list of nodes can be
  # supplied as optional first ordered argument, which are then converted into
  # features using +Net::State::Features.infer_from_nodes+ method. Similarly,
  # the features to exclude can be specifies as a list of nodes (or a
  # feature-specifying hash) supplied under +except:+ keyword. Otherwise, feature
  # specification can be passed to the method as named arguments. If no feature
  # specification is explicitly provided, it is assumed that all the features of
  # this dataset are meant to be plotted.
  # 
  def plot( nodes=nil, except: [], **named_args )
    puts "Hello from plot!"
    nn = named_args
    time = nn.may_have :time, syn!: :time_range
    events = events()
    # Figure out features.
    ff = if nodes.nil? then
           nn_ff = nn.slice [ :marking, :flux, :firing,
                              :gradient, :delta, :assignment ]
           nn_ff.empty? ? features : net.State.Features( nn_ff )
         else
           net.State.Features.infer_from_nodes( nodes )
         end
    # Figure out the features not to plot ("except" features).
    xff = case except
          when Array then net.State.Features.infer_from_nodes( except )
          when Hash then net.State.Features( except )
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
            if v.to_f.infinite? then inf += 1; 0.0
            elsif v.to_f.nan? then nan += 1; 0.0
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
