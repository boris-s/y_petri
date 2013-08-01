# encoding: utf-8

class YPetri::Net
  # Petri net state (marking of all its places).
  #
  class State < Array
    require_relative 'state/feature'
    require_relative 'state/features'

    class << self
      # Customization of the parametrize method for the State class: Its
      # dependents Feature and Features (ie. feature set) are also parametrized.
      # 
      def parametrize net: (fail ArgumentError, "No owning net!")
        Class.new( self ).tap do |subclass|
          subclass.define_singleton_method :net do net end
          subclass.param_class( { Feature: Feature,
                                  Features: Features },
                                with: { State: subclass } )
        end
      end

      delegate :Marking,
               :Firing,
               :Gradient,
               :Flux,
               :Delta,
               to: "Feature()"

      alias __new__ new

      # Revives a state from a record and a given set of marking clamps.
      # 
      def new record, marking_clamps: {}
        cc = marking_clamps.with_keys { |k| net.place k }.with_values! do |v|
          case v
          when YPetri::Place then v.marking
          when ~:call then v.call
          else v end
        end

        record = features( marking: net.pp - cc.keys ).load( record )

        __new__ net.pp.map do |p|
          begin; cc.fetch p; rescue IndexError
            record.fetch Marking().of( p )
          end
        end
      end

      # Returns the feature identified by the argument.
      # 
      def feature id
        case id
        when Feature() then id
        when Feature then id.class.new( id )
        else
          features( id ).tap do |ff|
            ff.size == 1 or fail ArgumentError, "Argument #{id} must identify " +
                                 "exactly 1 feature!"
          end.first
        end
      end

      # If the argument is an array of features, or another Features instance,
      # a feature set based on this array is returned. But the real purpose of
      # this method is to allow hash-type argument, with keys +:marking+,
      # +:firing+, +:gradient+, +:flux+ and +:delta+, specifying the respective
      # features. For +:marking+, an array of places (or Marking features) is
      # expected. For +:firing+ and +:flux+, an array of transitions (or Firing
      # / Flux features) is expected. For +:gradient+ and +:delta+, a hash value
      # is expected, containing keys +:places+ and +:transitions+, specifying
      # for which place set / transition set should gradient / delta features
      # be constructed. More in detail, values supplied under keys +:marking+,
      # +:firing+, +:gradient+, +:flux+ and +:delta+ are delegated to
      # +Features.marking+, +Features.firing+, +Features.gradient+ and
      # +Features.flux+ methods, and their results are joined into a single
      # feature set.
      # 
      def features arg
        case arg
        when Features(), Array then Features().new( arg )
        else # the real job of the method
          marking = arg[:marking] || []
          firing = arg[:firing] || [] # array of tS transitions
          gradient = arg[:gradient] || [ [], transitions: [] ]
          flux = arg[:flux] || [] # array of TS transitions
          delta = arg[:delta] || [ [], transitions: [] ]
          [ Features().marking( marking ),
            Features().firing( firing ),
            Features().gradient( *gradient ),
            Features().flux( flux ),
            Features().delta( *delta ) ].reduce :+
        end
      end

      delegate :marking, :firing, :gradient, :flux, :delta, to: "Features()"
    end

    # For non-parametrized vesion of the class, the class instance variables
    # hold the non-parametrized dependent classes.
    # 
    @Feature, @Features = Feature, Features

    delegate :net,
             :Feature,
             :Features,
             :features,
             :marking, :firing, :gradient, :flux, :delta,
             to: "self.class"

    # Reconstructs a simulation from the current state instance, given marking
    # clamps and other simulation settings.
    # 
    def reconstruct marking_clamps: {}, **settings
      net.simulation marking: to_hash,
                     marking_clamps: marking_clamps,
                     **settings
    end
  end # class State
end # YPetri::Net
