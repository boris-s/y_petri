# encoding: utf-8

# A collection of values for a given set of state features.
# 
class YPetri::Net::State::Features::Record < Array
  class << self
    delegate :State,
             :net,
             to: "Features()"

    # Constructs a new Record object from a given collection of values.
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
    return features.map &method( :fetch ) if precision.nil?
    features.map { |f| fetch( f ).round( precision ) }
  end

  # Pretty prints the record with feature names.
  # 
  def print gap: 4, precision: 4
    hsh = features.labels >> dump( precision: precision )
    hsh.pretty_print_numeric_values gap: gap, precision: precision
  end

  # Returns an identified feature, or fails.
  # 
  def fetch feature
    super begin
            Integer( feature )
          rescue TypeError
            feat = net.State.Feature( feature )
            features.index( feat )
          end
  end

  # Returns the state instance implied by the receiver record, and a set of
  # complementary marking clamps supplied as the argument.
  # 
  def state marking_clamps: {}
    cc = marking_clamps.with_keys { |k| net.place k }.with_values! do |v|
      case v
      when YPetri::Place then v.marking
      when ~:call then v.call
      else v end
    end
    own = features.marking.map &:place
    from_clamps = net.Places cc.keys
    fail TypeError, "Marking clamps supplied in the argument together with " +
      "this record's markings must complete the full state of the net!" unless
      net.places - own - from_clamps == []
    array = net.places.map do |place|
      begin; cc.fetch place; rescue IndexError
        fetch place
      end
    end
    State().new array
  end

  # Given a set of marking clamps complementary to the marking features of this
  # record, reconstructs a Simulation instance with the corresponding state.
  # If the net is timed, or if the construction of the simulation from the net
  # has need for any special settings, these must be supplied to this method.
  # (Timed nets eg. require +:time+ named argument for successful construction.)
  # 
  def reconstruct marking_clamps: {}, **settings
    clamped_places = net.Places( marking_clamps.keys )
    ff = features.marking - net.State.Features.Marking( clamped_places )
    m_hsh =
      ff.map { |f| f.place } >>
      marking
    net.simulation marking_clamps: marking_clamps, marking: m_hsh, **settings
  end

  # Expects a single array of marking feture identifiers, and selects the
  # corresponding values from the reciever record.
  # 
  def Marking array
    array.map { |id| fetch( net.State.Feature.Marking id ) }
    # possible TODO - maybe a new feature instance and reloading the record
    # through it woud be in place. Not doing now.
  end

  # Expects an arbitrary number of marking feature identifiers and returns
  # the corresponding values from the reciever record. If no arguments are
  # given, values for all the marking features are returned.
  # 
  def marking *marking_features
    return Marking( features.marking ) if marking_features.empty?
    Marking( marking_features )
  end

  # Expects a single aarray of flux feature identifiers, and selects the
  # corresponding values from the reciever record.
  # 
  def Flux array
    array.map { |id| fetch( net.State.Feature.Flux id ) }
  end

  # Expects an arbitrary number of flux feature identifiers and returns the
  # corresponding values from the reciever record. If no arguments are given,
  # values for all the flux features are returned.
  # 
  def flux *flux_features
    return Flux( features.flux ) if flux_features.empty?
    Flux( flux_features )
  end

  # Expects a single aarray of firing feature identifiers, and selects the
  # corresponding values from the reciever record.
  # 
  def Firing array
    array.map { |id| fetch( net.State.Feature.Firing id ) }
  end

  # Expects an arbitrary number of firing feature identifiers and returns the
  # corresponding values from the reciever record. If no arguments are given,
  # values for all the firing features are returned.
  # 
  def firing *firing_features
    return Firing( features.firing ) if firing_features.empty?
    Firing( firing_features )
  end

  # Expects a single array of gradient feature identifiers, optionally qualified
  # by the +:transitions+ named argument, defaulting to all T transitions in the
  # net.
  # 
  def Gradient array, transitions: nil
   array.map { |id|
      fetch( net.State.Feature.Gradient id, transitions: transitions )
    }
  end

  # Expects an arbitrary number of gradient feature identifiers, optionally
  # qualified by the +:transitions+ named argument, defaulting to all T
  # transitions in the net. If no arguments are given, values for all the
  # gradient features are defined.
  # 
  def gradient *gradient_features, transitions: nil
    return Gradient( gradient_features, transitions: transitions ) unless
      gradient_features.empty?
    return Gradient( features.gradient ) if transitions.nil?
    Gradient( features.gradient.select do |f|
                f.transitions == transitions.map { |t| net.transition t }
              end )
  end

  # Returns the values for a set of delta features selected from this record's
  # feature set. Expects a single array argument, optionally qualified by
  # by +:transitions+ named argument, defaulting to all the transitions in the
  # net.
  # 
  def Delta array, transitions: nil
    array.map { |id|
      fetch( net.State.Feature.Delta id, transitions: net.tt( transitions ) )
    }
  end

  # Returns the values for a set of delta features selected from this record's
  # feature set. Expects an arbitrary number of arguments, optionally qualified
  # by +:transitions+ named argument, defaulting to all the transitions in the
  # net. Without arguments, returns values for all the delta features.
  # 
  def delta *delta_features, transitions: nil
    return Delta( delta_features, transitions: transitions ) unless
      delta_features.empty?
    return Delta( features.delta ) if transitions.nil?
    Delta( features.delta.select do |f|
             f.transitions == transitions.map { |t| net.transition t }
           end )
  end

  # Returns the values for a set of assignment features selected from this
  # record's feature set. Expects a single array argument, optionally qualified
  # by +:transition+ named argument.
  # 
  def Assignment array, transition: L!
    return array.map { |id| fetch net.State.Feature.Assignment( id ) } if
      transition.local_object?
    array.map { |id|
      fetch net.State.Feature.Assignment( id, transition: transition )
    }
  end

  # Returns the values for a set of assignment features selected from this
  # record's feature set. Expects an arbitrary number of arguments, optinally
  # qualified by +:transition+ named argument. Without arguments, returns
  # values for all the assignment features.
  # 
  def assignment *ids, transition: L!
    if transition.local_object? then
      return Assignment( ids ) unless ids.empty?
      Assignment features.assignment
    else
      return Assignment( ids, transition: transition ) unless ids.empty?
      Assignment features.assignment, transition: transition
    end
  end

  # Computes the Euclidean distance from another record.
  # 
  def euclidean_distance( other )
    fail TypeError unless features == other.features
    sum_of_squares = zip( other )
      .map { |a, b| a - b }
      .map { |d| d * d }
      .reduce( 0.0, :+ )
    sum_of_squares ** 0.5
  end
end # class YPetri::Net::State::Features::Record
