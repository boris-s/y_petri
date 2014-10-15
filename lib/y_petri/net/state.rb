# encoding: utf-8

# An array whose elements represent marking of places of a +YPetri::Net+.
# 
class YPetri::Net::State < Array
  require_relative 'state/feature'
  require_relative 'state/features'

  class << self
    # Customization of the parametrize method for the State class: Its dependents
    # Feature and Features (feature set class) are also parametrized.
    # 
    def parametrize net: ( fail ArgumentError, "No owning net!" )
      Class.new( self ).tap do |ç|
        ç.define_singleton_method :net do net end
        ç.param_class!( { Feature: Feature,
                          Features: Features },
                        with: { State: ç } )
      end
    end

    # Returns the feature identified by the argument.
    # 
    def Feature arg=nil, **named_args
      case arg
      when Feature() then arg
      when Feature then arg.class.new( arg )
      when nil then
        key, val = named_args.first
        case key
        when :marking then Feature().Marking( val )
        when :firing then Feature().Firing( val )
        when :flux then Feature().Flux( val )
        when :gradient then Feature().Gradient( *val )
        when :delta then Feature().Delta( *val )
        when :assignment then Feature().Assignment( val )
        else fail ArgumentError, "Unrecognized feature: #{key}!"
        end
      else
        Feature().infer_from_node( arg )
      end
    end

    # A constructor of a +Features+ instance. Note that the message +:Features+
    # called without arguments is intercepted by a singleton method and returns
    # the parametrized subclass of +State::Features+ owned by this class.
    # 
    # This method may accept a single array-type argument, constructing a feature
    # set out of it. Alternatively, the method may accept named arguments:
    # +:marking+, +:firing+, +:gradient+, +:flux+, +:delta+, and +:assignment+,
    # specifying the a single (possibly mixed) feature set.
    # 
    def Features array=nil, **named_args
      Features()[ *array, **named_args ]
    end
  end # class << self

  # For non-parametrized vesion of the class, should it ever be used in such way,
  # the class instance variables hold the non-parametrized dependent classes.
  # 
  @Feature, @Features = Feature, Features

  delegate :net,
           :Feature,             # Note that as syntactic salt, specific methods
           :Features,            # #firing, #gradient, #flux etc. are not
           :features,            # delegated to self.class.
           to: "self.class"
  # FIXME: #features method above actually doesn't work in practice, self.class
  # doesn't have it.

  # Given a set of clamped places, this method outputs a +Record+ instance
  # containing the marking of the free places (complementary to the supplied
  # set of clamped places). I no set of clamped places is supplied, it is
  # considered empty.
  # 
  def to_record clamped_places
    free_places = case clamped_places
                  when Hash then to_record( clamped_places.keys )
                  else
                    places - places( clamped_places )
                  end
    features( marking: free_places ).Record.load markings( free_places )
  end # FIXME: I find it not working atm.

  # Marking of a single given place in this state.
  # 
  def marking place
    self[ net.places.index net.place( place ) ]
  end

  # Expects an arbitrary number of places or place ids, and returns an array
  # of their markings as per the receiver +State+ instance.
  # 
  def markings *places
    places.map &method( :marking )
  end
end # YPetri::Net::State
