# encoding: utf-8

# A set of state features.
# 
class YPetri::Net::State::Features < Array
  require_relative 'features/record'

  class << self
    # Customization of the parametrize method for the Features class: Its
    # dependents Record and Dataset are also parametrized.
    # 
    def parametrize parameters
      Class.new( self ).tap do |ç|
        parameters.each_pair { |symbol, value|
          ç.define_singleton_method symbol do value end
        }
        ç.param_class( { Record: Record,
                         DataSet: YPetri::Net::DataSet },
                       with: { Features: ç } )
      end
    end

    delegate :net, to: "State()"
    delegate :load, to: "Record()"

    alias __new__ new

    def new features
      features = features.map &State().method( :Feature )
      __new__( features ).tap do |inst|
        # Parametrize them <em>one more time</em> with Features instance.
        # Banged version of #param_class! ensures that #Record, #Dataset
        # methods are shadowed.
        inst.param_class!( { Record: Record(),
                             DataSet: DataSet() },
                           with: { features: inst } )
      end
    end

    # Takes an arbitrary number of ordered arguments identifying features, or
    # named arguments +:marking+, +:firing+, +:gradient+, +:flux+, +:delta+,
    # +:assignment+ containing arrays identifying the corresponding type of
    # features.
    # 
    def [] *ordered_args, **named_args
      unless ordered_args.empty?
        fail ArgumentError, "Named arguments must not be given if ordered " +
          "arguments are given!" unless named_args.empty?
        return infer_from_elements( ordered_args )
      end
      a = []
      a << Marking( Array named_args[ :marking ] ) if named_args[ :marking ]
      a << Firing( Array named_args[ :firing ] ) if named_args[ :firing ]
      a << Flux( Array named_args[ :flux ] ) if named_args[ :flux ]
      if named_args[ :gradient ] then
        ordered = Array( named_args[ :gradient ] )
        named = ordered.extract_options!
        a << Gradient( ordered, **named )
      end
      if named_args[ :delta ] then
        ordered = Array( named_args[ :delta ] )
        named = ordered.extract_options!
        a << Delta( ordered, **named )
      end
      if named_args[ :assignment ] then
        ordered = Array( named_args[ :assignment ] )
        named = ordered.extract_options!
        a << Assignment( ordered, **named )
      end
      a.size == 1 ? a.first : a.reduce( new( [] ), :+ )
    end

    # Constructs a set of marking features from an array of marking feature
    # identifiers.
    # 
    def Marking array
      new array.map &net.State.Feature.method( :Marking )
    end

    # Expects an arbitrary number of marking feature identifiers and constructs
    # a feature set out of them. Without arguments, full marking feature set
    # for the underlying net is returned.
    # 
    def marking *marking_feature_identifiers
      return Marking net.pp if marking_feature_identifiers.empty?
      Marking marking_feature_identifiers
    end

    # Constructs a set of firing features from an array of firing feature
    # identifiers.
    # 
    def Firing array, **named_args
      new array.map &net.State.Feature.method( :Firing )
    end

    # Expects an arbitrary number of firing feature identifiers and constructs
    # a feature set out of them. Without arguments, full firing feature set
    # (all S transitions) for the underlying net is returned.
    # 
    def firing *firing_feature_identifiers
      return Firing net.S_tt if firing_feature_identifiers.empty?
      Firing firing_feature_identifiers
    end

    # Constructs a set of gradient features from an array of gradient feature
    # identifiers, optionally qualified by an array of transitions supplied via
    # the named argument +:transitions+.
    # 
    def Gradient array, transitions: nil
      return new array.map &net.State.Feature.method( :Gradient ) if
        transitions.nil?
      ary = array.map { |id|
        net.State.Feature.Gradient id, transitions: transitions
      }
      new ary
    end

    # Expects an arbitrary number of gradient feature identifiers and constructs
    # a feature set out of them, optionally qualified by an array of transitions
    # supplied via the named argument +:transitions+. Returns the corresponding
    # feature set. Without ordered arguments, full gradient feature set for the
    # underlying net is returned.
    # 
    def gradient *args, transitions: nil
      return Gradient args, transitions: transitions unless args.empty?
      return Gradient net.pp, transitions: net.T_tt if transitions.nil?
      Gradient net.pp, transitions: transitions
    end

    # Constructs a set of flux features from an array of flux feature
    # identifiers.
    # 
    def Flux array
      new array.map &net.State.Feature.method( :Flux )
    end

    # Expects an arbitrary number of flux feature identifiers and constructs
    # a feature set out of them. Without arguments, full flux feature set for
    # the underlying net is returned.
    # 
    def flux *flux_feature_identifiers
      return Flux net.TS_tt if flux_feature_identifiers.empty?
      Flux flux_feature_identifiers
    end

    # Constructs a set of delta features from an array of delta feature
    # identifiers, optionally qualified by an array of transitions supplied via
    # the named argument +:transitions+.
    # 
    def Delta array, transitions: nil
      return new array.map &net.State.Feature.method( :Delta ) if
        transitions.nil?
      new array.map { |id|
        net.State.Feature.Delta id, transitions: transitions
      }
    end

    # Expects an arbitrary number of delta feature identifiers and constructs
    # a feature set out of them, optionally qualified by an array of transitions
    # supplied via the named argument +:transitions+. Returns the corresponding
    # feature set. Without ordered arguments, full delta feature set for the
    # underlying net is returned.
    # 
    def delta *args, transitions: L!
      return Delta args, transitions: transitions unless args.empty?
      fail ArgumentError, "Sorry, but feature set constructor Features.delta " +
        "cannot be used without :transitions named argument, because it is " +
        "ambiguous whether the transition set should default to the timed or " +
        "timeless transitions (they cannot be mixed together when " +
        "constructing a delta feature). Please specify the transitions, or " + 
        "disambiguate timedness by using either .delta_timed or " +
        ".delta_timeless method " if transitions.local_object?
      Delta net.pp, transitions: transitions
    end

    # Expects an arbitrary number of place idetifiers and constructs a feature
    # set out of them, optionally qualified by an array of T transitions supplied
    # via the named argument +:transitions+. Returns the corresponding feature
    # set. Without ordered arguments, full delta feature set for the underlying
    # net is returned. If no transitions are supplied, full set of T transitions
    # is assumed.
    # 
    def delta_timed *args, transitions: L!
      return delta *args, transitions: net.T_transitions if
        transitions.local_object?
      delta *args, transitions: net.T_Transitions( Array( transitions ) )
    end

    # Expects an arbitrary number of place idetifiers and constructs a feature
    # set out of them, optionally qualified by an array of t (timeless)
    # transitions supplied via the named argument +:transitions+. Returns the
    # corresponding feature set. Without ordered arguments, full delta feature
    # set for the underlying net is returned. If no transitions are supplied,
    # full set of t (timeless) transitions is assumed.
    # 
    def delta_timeless *args, transitions: L!
      return delta *args, transitions: net.t_transitions if
        transitions.local_object?
      delta *args, transitions: net.t_Transitions( Array( transitions ) )
    end

    # Constructs a set of assignment features from an array of assignment feature
    # identifiers.
    # 
    def Assignment array, transition: L!
      if transition.local_object? then
        new array.map &net.State.Feature.method( :Assignment )
      else
        new array.map { |id|
          net.State.Feature.Assignment id, transition: transition
        }
      end
    end

    # Expects an arbitrary number of assignment feature identifiers and
    # constructs a feature set out of them.
    # 
    def assignment *ids, transition: L!
      if transition.local_object? then
        fail ArgumentError, "Sorry, but Features.assignment method cannot " +
          "be called without arguments. There is a convenience method " +
          "Features.aa available, returning all the assignment features " +
          "for the places with exactly one A transition upstream, if that." +
          "is what you mean." if ids.empty?
        Assignment( ids )
      else
        return Assignment( ids, transition: transition ) unless ids.empty?
        Assignment net.transition( transition ).codomain, transition: transition
      end
    end

    # Convenience method that returns the full set of assignment features
    # for those places, which have exactly one A transition in their upstream
    # arcs.
    # 
    def aa
      Assignment net.places.select { |p|
        upstream = p.upstream_arcs
        upstream.size == 1 && upstream.first.A?
      }
    end

    # Takes an array of the net elements (places and/or transitions), and infers
    # a feature set from them in the following way: Places or place ids are
    # converted to marking features. The remaining array elements are treated
    # as transition ids, and are converted to either flux features (if the
    # transition is timed), or firing features (if the transition is timeless).
    # 
    def infer_from_elements( elements )
      new elements.map &net.State.Feature.method( :infer_from_element )
    end
  end

  delegate :net, to: "self.class"

  delegate :load, to: "Record()" # Beware! #Record instance method returns
                                 # a double parametrized subclass not identical
                                 # to the one available via #Record class method.

  # Note that this method expects a single array argument. Message +:Record+
  # without arguments is intercepted by a singleton method.
  # 
  alias Record load

  # Extracts the features from a given target, returning a record.
  # 
  def extract_from target, **nn
    values = map { |feature| feature.extract_from( target, **nn ) }
    Record( values )
  end

  # Interpolation operator +%+ acts as an alias for the +#extract_from+ feature
  # extraction method.
  # 
  def % operand
    args = Array( operand )
    named_args = args.extract_options!
    extract_from args, **named_args
  end

  # Summation of feature sets.
  # 
  def + other
    self.class.new( super )
  end

  # Subtraction of feature sets.
  # 
  def - other
    self.class.new( super )
  end

  # Multiplication (like in arrays).
  # 
  def * other
    self.class.new( super )
  end

  # Labels of the features of the receiver feature set.
  # 
  def labels
    map &:label
  end

  # Expects a hash identifying a set of features, that is a subset of the
  # current set of features.
  # 
  def reduce_features features
    net.State.features( features ).tap do |ff|
      msg = "The argument must identify a subset of the current feature set!"
      fail TypeError, msg unless ( ff - self ).empty?
    end
  end

  # Returns a subset of marking features selected from this feature set. Expects
  # a single array argument.
  # 
  def Marking array
    array = array.map do |id|
      net.State.Feature.Marking( id ).tap do |f|
        include? f or fail KeyError, "No marking feature '#{f}' in this set!"
      end
    end
    self.class.new array
  end

  # Returns a subset of marking features selected from this feature set. Expects
  # an arbitrary number of arguments. Without arguments, selects all of them.
  # 
  def marking *ids
    return Marking ids unless ids.empty?
    self.class.new select { |f| f.is_a? net.State.Feature.Marking }
  end

  # Returns a subset of firing features selected from this feature set. Expects
  # a single array argument.
  # 
  def Firing array
    self.class.new array.map { |id|
      net.State.Feature.Firing( id ).tap do |f|
        include? f or fail KeyError, "No firing feature '#{f}' in this set!"
      end
    }
  end

  # Returns a subset of firing features selected from this feature set. Expects
  # an arbitrary number of arguments. Without arguments, selects all of them.
  # 
  def firing *ids
    return Firing ids unless ids.empty?
    self.class.new select { |f| f.is_a? net.State.Feature.Firing }
  end

  # Returns a subset of flux features selected from this feature set. Expects
  # a single array argument.
  # 
  def Flux array
    self.class.new array.map { |id|
      net.State.Feature.Flux( id ).tap do |f|
        include? f or fail KeyError, "No flux feature '#{f}' in this set!"
      end
    }
  end

  # Returns a subset of flux features selected from this feature set. Expects
  # an arbitrary number of arguments. Without arguments, selects all of them.
  # 
  def flux *ids
    return Flux ids unless ids.empty?
    self.class.new select { |f| f.is_a? net.State.Feature.Flux }
  end

  # Returns a subset of gradient features selected from this feature set.
  # Expects a single array argument, optionally qualified by +:transitions+
  # named argument, defaulting to all T transitions in the net.
  # 
  def Gradient array, transitions: nil
    self.class.new array.map { |id|
      net.State.Feature.Gradient( id, transitions: transitions ).tap do |f|
        include? f or fail KeyError, "No flux feature '#{f}' in this set!"
      end
    }
  end

  # Returns a subset of gradient features selected from this feature set.
  # Expects an arbitrary number of arguments, optionally qualified by
  # +:transitions+ named argument, defaulting to all T transitions in the
  # net. Without arguments, selects all of them.
  # 
  def gradient *ids, transitions: L!
    return Gradient ids, transitions: transitions unless ids.empty?
    if transitions.local_object? then
      self.class.new select { |f| f.is_a? net.State.Feature.Gradient }
    else
      self.class.new select { |f| f.transitions == net.tt( Array transitions ) }
    end
  end

  # Returns a subset of delta features selected from this feature set.
  # Expects a single array argument, optionally qualified by +:transitions+
  # named argument, defaulting to all the transitions in the net.
  # 
  def Delta array, transitions: nil
    self.class.new array.map { |id|
      net.State.Feature.Delta( id, transitions: transitions ).tap do |f|
        include? f or
          fail KeyError, "No delta feature '#{f}' in this feature set!"
      end
    }
  end

  # Returns a subset of delta features selected from this feature set.
  # Expects an arbitrary number of arguments, optionally qualified by
  # +:transitions+ named argument, defaulting to all the transitions in the
  # net. Without arguments, selects all the delta features.
  #
  def delta *ids, transitions: L!
    return Delta ids, transitions: transitions unless ids.empty?
    if transitions.local_object? then
      self.class.new select { |f| f.is_a? net.State.Feature.Delta }
    else
      self.class.new select { |f| f.transitions == net.tt( Array transitions ) }
    end
  end

  # Returns a subset of assignment features selected from this feature set.
  # Expects a single array argument.
  # 
  def Assignment array
    self.class.new array.map { |id|
      net.State.Feature.Assignment( id ).tap do |f|
        include? f or fail KeyError, "No flux feature '#{f}' in this set!"
      end
    }
  end

  # Returns a subset of assignment features selected from this feature set.
  # Expects an arbitrary number of arguments. Without arguments, selects all
  # of them.
  # 
  def assignment *ids
    return Assignment ids unless ids.empty?
    self.class.new select { |f| f.is_a? net.State.Feature.Assignment }
  end

  # Returns a string briefly describing the feature set.
  # 
  def to_s
    group_by( &:type )
      .map { |feature_type, ff| "#{feature_type}: #{ff.size}" }
      .join ', '
  end

  # Inspect string of the instance.
  # 
  def inspect
    "#<Features: #{to_s}>"
  end
end # YPetri::Net::State::Features
