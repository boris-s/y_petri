# encoding: utf-8

class YPetri::Net::State
  # A set of state features.
  # 
  class Features < Array
    require_relative 'features/record'
    require_relative 'features/dataset'

    class << self
      # Customization of the parametrize method for the Features class: Its
      # dependents Record and Dataset are also parametrized.
      # 
      def parametrize *args
        super.tap do |ç|
          ç.param_class( { Record: Record,
                           Dataset: Dataset }, with: { Features: ç } )
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

      delegate :load, to: :Record

      alias __new__ new

      def new features
        ff = features.map &method( :feature )
        __new__( ff ).tap do |inst|
          # Parametrize them <em>one more time</em> with Features instance.
          # Banged version of #param_class! ensures that #Record, #Dataset
          # methods are shadowed.
          inst.param_class!( { Record: Record(),
                               Dataset: Dataset() }, with: { features: ff } )
        end
      end

      def marking places: net.pp
        new net.pp( places ).map { |p| Marking( p ) }
      end

      def firing transitions: net.tS_tt
        new net.tS_tt( transitions ).map { |t| Firing( t ) }
      end

      def gradient places: net.pp, transitions: net.T_tt
        tt = net.T_tt( transitions )
        new net.pp( places ).map { |p|
          Gradient( p, transitions: tt )
        } 
      end

      def flux transitions: net.TS_tt
        new net.TS_tt( transitions ).map { |t| Flux( t ) }
      end

      def delta places: net.pp, transitions: net.tt
        tt = net.tt( transitions )
        new net.pp( places ).map { |p|
          Delta( p, transitions: tt )
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
             :load,
             to: "self.class"

    # Extracts the features from a given target
    # 
    def extract_from target, **nn
      Record().new( map { |feature| feature.extract_from( target, **nn ) } )
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
  end # class Features
end # YPetri::Net::State
