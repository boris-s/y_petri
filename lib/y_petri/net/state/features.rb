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

    delegate :net,
             :Feature,
             :feature,
             to: "State()"

    delegate :Marking,
             :Firing,
             :Gradient,
             :Flux,
             :Delta,
             to: "Feature()"

    delegate :load, to: "Record()"

    alias __new__ new

    def new features
      array = features.map &method( :feature )
      __new__( array ).tap do |inst|
        # Parametrize them <em>one more time</em> with Features instance.
        # Banged version of #param_class! ensures that #Record, #Dataset
        # methods are shadowed.
        inst.param_class!( { Record: Record(), DataSet: DataSet() },
                           with: { features: inst } )
      end
    end

    # Takes an array of marking feature identifiers (places, Marking instances),
    # and returns the corresponding array of marking features valid for the
    # current net. If no argument is given, an array of all the marking features
    # of the current net is returned.
    # 
    def marking arg=nil
      return marking net.pp if arg.nil?
      new arg.map { |id| Marking id }
    end

    # Takes an array of firing feature identifiers (transitions, Firing
    # instances), and returns the corresponding array of firing features valid
    # for the current net. If no argument is given, an array of all the firing
    # features of the current net is returned.
    # 
    def firing arg=nil
      return firing net.tS_tt if arg.nil?
      new arg.map { |id| Firing id }
    end

    # Takes an array of gradient feature identifiers (places, Marking instances),
    # qualified by an array of transitions (named argument +:transitions+,
    # defaults to all the timed transitions in the net), and returns the
    # corresponding array of gradient features valid for the current net. If no
    # argument is given, an array of all the gradient features qualified by the
    # +:transitions+ argument is returned.
    # 
    def gradient arg=nil, transitions: nil
      if arg.nil? then
        return gradient net.pp, transitions: net.T_tt if transitions.nil?
        gradient net.pp, transitions: transitions
      else
        return new arg.map { |id| Gradient id } if transitions.nil?
        new arg.map { |id| Gradient id, transitions: transitions }
      end
    end

    # Takes an array of flux feature identifiers (transitions, Flux instances),
    # and returns the corresponding array of flux features valid for the current
    # net. If no argument is given, an array of all the flux features of the
    # current net is returned.
    # 
    def flux arg=nil
      return flux net.TS_tt if arg.nil?
      new arg.map { |t| Flux t }
    end

    # Takes an array of delta feature identifiers (places, Delta instances),
    # qualified by an array of transitions (named argument +:transitions+,
    # defaults to all the transitions in the net), and returns the corresponding
    # array of delta features valid for the current net. If no argument is
    # given, an array of all the delta features qualified by the +:transitions+
    # argument is returned.
    # 
    def delta arg=nil, transitions: nil
      if arg.nil? then
        return delta net.pp, transitions: net.tt if transitions.nil?
        delta net.pp, transitions: transitions
      else
        return new arg.map { |id| Delta id } if transitions.nil?
        new arg.map { |id| Delta id, transitions: transitions }
      end
    end

    # Takes an array of the net elements (places and/or transitions), and infers
    # a feature set from them in the following way: Places or place ids are
    # converted to marking features. The remaining array elements are treated
    # as transition ids, and are converted to either flux features (if the
    # transition is timed), or firing features (if the transition is timeless).
    # 
    def infer_from_elements( net_elements )
      new net_elements.map { |e| net.element( e ) }.map { |e|
        element, element_type = case e
                                when Feature() then [ e, :feature ]
                                else
                                  begin
                                    [ net.place( e ), :place ]
                                  rescue TypeError, NameError
                                    [ net.transition( e ), :transition ]
                                  end
                                end
        case element_type
        when :feature then element
        when :place then Marking( element )
        when :transition then
          fail TypeError, "Flux / firing features can only be auto-inferred " +
            "from S transitions! (#{element} was given)" unless element.S?
          element.timed? ? Flux( element ) : Firing( element )
        end
      }
    end
  end

  delegate :State,
           :net,
           :Feature,
           :feature,
           :Marking,
           :Firing,
           :Gradient,
           :Flux,
           :Delta,
           to: "self.class"

  delegate :load,
           to: "Record()"

  alias new_record load

  # Extracts the features from a given target, returning a +Record+ instance.
  # 
  def extract_from target, **nn
    values = map { |feat| feat.extract_from( target, **nn ) }
    new_record( values )
  end

  # Constructs a new +Record+ instance from the supplied values array. The
  # values in the array must correspond to the receiver feature set.
  # 
  def new_record values
    Record().load values
  end

  # Constructs a new dataset based on the receiver feature set.
  # 
  def new_dataset *args, &blk
    DataSet().new *args, &blk
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

  # Returns the subset of marking features.

  # Expects a marking feature identifier (place identifier or Marking instance),
  # and returns the corresponding feature from this feature set. If an array of
  # marking feature identifiers is supplied, it is mapped to the array of
  # corresponding features from this feature set. If no argument is given, all
  # the marking features from this set are returned.
  #
  def marking arg=nil
    return marking( select { |feat| feat.is_a? Marking() } ) if arg.nil?
    case arg
    when Array then self.class.new( arg.map { |id| marking id } )
    else
      Marking( arg ).tap do |feature|
        include? feature or
          fail KeyError, "No marking feature '#{arg}' in this feature set!"
      end
    end
  end

  # Expects a firing feature idenfier (tS transition identifier, or Firing
  # instance), and returns the corresponding feature from this feature set. If
  # an array of firing feature identifiers is supplied, it is mapped to the
  # array of corresponding features from this feature set. If no argument is
  # given, all the firing features from this set are returned.
  #
  def firing arg=nil
    return firing( select { |feat| feat.is_a? Firing() } ) if arg.nil?
    case arg
    when Array then self.class.new( arg.map { |id| firing id } )
    else
      Firing( arg ).tap do |feature|
        include? feature or
          fail KeyError, "No firing feature '#{arg}' in this feature set!"
      end
    end
  end

  # Expects a flux feature identifier (TS transition identifier, or Flux
  # instance), and returns the corresponding feature from this feature set. If
  # an array of flux feature identifiers is supplied, it is mapped to the array
  # of corresponding features from this feature set. If no argument is given,
  # all the flux features from this set are returned.
  #
  def flux arg=nil
    return flux( select { |feat| feat.is_a? Flux() } ) if arg.nil?
    case arg
    when Array then self.class.new( arg.map { |id| flux id } )
    else
      Flux( arg ).tap do |feature|
        include? feature or
          fail KeyError, "No flux feature '#{arg}' in this feature set!"
      end
    end
  end

  # Expects a gradient feature identifier (place identifier, or Gradient
  # instance), qualified by an array of transitions (named argument
  # +:transitions+, defaults to all timed transitions in the net), and
  # returns the corresponding feature from this feature set. If an array of
  # gradient feature identifiers is supplied, it is mapped to the array of
  # corresponding features from this feature set. If no argument is given,
  # all the gradient features from this feature set are returned.
  # 
  def gradient arg=nil, transitions: nil
     if arg.nil? then
       return gradient( select { |feat| feat.is_a? Gradient() } ) if
         transitions.nil?
       gradient.select { |feat| feat.transitions == net.tt( transitions ) }
     else
       case arg
       when Array then
         self.class.new( arg.map { |id| gradient id, transitions: transitions } )
       else
         Gradient( arg, transitions: transitions ).tap do |feature|
           include? feature or
             fail KeyError, "No gradient feature '#{arg}' in this fature set!"
         end
       end
     end
  end

  # Expects a delta feature identifier (place identifier, or Gradient instance),
  # qualified by an array of transitions (named argument +:transitions+,
  # defaulting to all the transtitions in the net), and returns the
  # corresponding feature from this feature set. If an array of delta feature
  # identifiers is supplied, it is mapped to the array of corresponding features
  # from thie feature set.
  #
  def delta arg=nil, transitions: nil
    if arg.nil? then
      return delta( select { |feat| feat.is_a? Delta() } ) if
        transitions.nil?
      delta.select { |feat| feat.transitions == net.tt( transitions ) }
    else
      case arg
      when Array then
        self.class.new( arg.map { |id| delta id, transitions: transitions } )
      else
        Delta( arg, transitions: transitions ).tap do |feature|
          include? feature or
            fail KeyError, "No delta feature '#{arg}' in this feature set!"
        end
      end
    end
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
