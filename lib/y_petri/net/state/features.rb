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
                         Dataset: YPetri::Net::DataSet },
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
        inst.param_class!( { Record: Record(), Dataset: Dataset() },
                           with: { features: inst } )
      end
    end

    def marking places=net.pp
      new net.pp( places ).map { |p| Marking( p ) }
    end

    def firing transitions=net.tS_tt
      new net.tS_tt( transitions ).map { |t| Firing( t ) }
    end

    def gradient places=net.pp, transitions: net.T_tt
      tt = net.T_tt( transitions )
      new net.pp( places ).map { |p|
        Gradient( p, transitions: tt )
      }
    end

    def flux transitions=net.TS_tt
      new net.TS_tt( transitions ).map { |t| Flux( t ) }
    end

    def delta places=net.pp, transitions: net.tt
      transitions = net.tt( transitions )
      new net.pp( places ).map { |p|
        Delta( p, transitions: transitions )
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

  # Extracts the features from a given target
  # 
  def extract_from target, **nn
    new_record( map { |feature| feature.extract_from( target, **nn ) } )
  end

  # Constructs a new dataset from these features.
  # 
  def new_dataset
    Dataset().new
  end

  # Feature summation -- of feature class.
  # 
  def + other
    self.class.new( super )
  end

  # Feature summation -- of feature class.
  # 
  def - other
    self.class.new( super )
  end

  # Feature summation -- of feature class.
  # 
  def * other
    self.class.new( super )
  end

  # Feature labels.
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
  #
  def marking place_ids=nil
    return marking( select { |f| f.is_a? Marking() } ) if place_ids.nil?
    reduce_features marking: place_ids
  end

  # Returns the subset of firing features.
  #
  def firing
    fail NotImplementedError
  end

  # Returns the subset of flux features.
  #
  def flux
    fail NotImplementedError
  end

  # Returns the subset of gradient features.
  #
  def gradient
    fail NotImplementedError
  end

  # Returns the subset of delta features.
  #
  def delta
    fail NotImplementedError
  end
end # YPetri::Net::State::Features
