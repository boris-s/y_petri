# encoding: utf-8

# An array whose elements correspond to the full marking of the net's places.
#
class YPetri::Net::State < Array
  require_relative 'state/feature'
  require_relative 'state/features'

  class << self
    # Customization of the parametrize method for the State class: Its
    # dependents Feature and Features (ie. feature set) are also parametrized.
    # 
    def parametrize net: (fail ArgumentError, "No owning net!")
      Class.new( self ).tap do |ç|
        ç.define_singleton_method :net do net end
        ç.param_class( { Feature: Feature,
                         Features: Features },
                       with: { State: ç } )
      end
    end

    delegate :Marking,
             :Firing,
             :Gradient,
             :Flux,
             :Delta,
             to: "Feature()"

    # Returns the feature identified by the argument.
    # 
    def feature *id
      case id.first
      when Feature() then id.first
      when Feature then id.first.class.new( id.first )
      else
        features( id ).tap do |ff|
          msg =  "Arguments must identify exactly 1 feature!"
          ff.size == 1 or fail ArgumentError, msg
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

  # Given a set of clamped places,  this method outputs a Record instance
  # containing the marking of the free places (complementary to the supplied
  # set of clamped places). I no set of clamped places is supplied, it is
  # considered empty.
  # 
  def to_record clamped_places=[]
    free_places = case clamped_places
                  when Hash then to_record( clamped_places.keys )
                  else
                    free_places = places - places( clamped_places )
                  end
    features( marking: free_places ).Record.load markings( free_places ) 
  end

  # Marking of a single given place in this state.
  # 
  def marking place_id
    self[ places.index place( place_id ) ]
  end

  # Returns an array of markings of particular places in this state..
  # 
  def markings place_ids=nil
    return markings( places ) if place_ids.nil?
    place_ids.map &:marking
  end
end # YPetri::Net::State
