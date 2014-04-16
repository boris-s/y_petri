# encoding: utf-8

# Firing of an S transition. (Firing is only defined on S transitions, whose
# action can be computed as firing * stoichometry_vector_of_the_transition.)
# 
class YPetri::Net::State::Feature::Firing < YPetri::Net::State::Feature
  attr_reader :transition

  class << self
    # Customization of the Class#parametrize method.
    # 
    def parametrize *args
      Class.instance_method( :parametrize ).bind( self ).( *args ).tap do |ç|
        # First, prepare the hash of instances.
        hsh = Hash.new do |hsh, id|
          case id
          when self then # missing key "id" is a Firing instance
            hsh[ id.transition ]
          when ç.net.Transition then
            t = begin
                  ç.net.S_transitions( id ).first
                rescue TypeError => err
                  msg = "Transition #{id} not " +
                    "recognized as tS transition in " +
                    "net #{ç.net}! (%s)"
                  raise TypeError, msg % err
                end
            hsh[ id ] = t.timed? ? ç.timed( t ) : ç.timeless( t )
          else
            hsh[ ç.net.transition( id ) ]
          end
        end
        # And then, assign it to the :@instances variable.
        ç.instance_variable_set :@instances, hsh
      end
    end

    attr_reader :instances

    alias __new__ new

    def new id
      instances[ id ]
    end

    # Alias of #new method.
    # 
    def of id
      new id
    end

    # Expects a single timed transition and constructs a timed firing feature.
    # 
    def timed id
      __new__( net.T_tt( id ).first )
        .tap { |i| i.instance_variable_set :@timed, true }
    end

    # Expects a single timeless transition and constructs a timeless firing
    # feature.
    # 
    def timeless id
      __new__( net.t_tt( id ).first )
        .tap { |i| i.instance_variable_set :@timed, false }
    end
  end

  # The constructor of a marking feature takes exactly one argument (transition
  # identifier).
  # 
  def initialize transition
    @transition = net.transition( transition )
  end

  # Extracts the value of this feature from the target (eg. a simulation).
  # If the receiver firing feature is timed, this method requires an additional
  # named argument +:delta_time+, alias +:Δt+.
  # 
  def extract_from arg, **named_args
    case arg
    when YPetri::Simulation then
      if timed? then
        arg.send( :TS_transitions, transition ).first
          .firing( named_args.must_have :delta_time, syn!: :Δt )
      else
        arg.send( :tS_transitions, transition ).first.firing
      end
    else
      fail TypeError, "Argument type not supported!"
    end
  end

  # Is the delta feature timed?
  # 
  def timed?
    @timed
  end

  # Opposite of +#timed?+.
  # 
  def timeless?
    ! timed?
  end

  # Type of this feature.
  # 
  def type
    :firing
  end

  # A string briefly describing the firing feature.
  # 
  def to_s
    label
  end

  # Label for the firing feature (to use in the graphics etc.)
  # 
  def label
    "F:#{transition.name}"
  end

  # Inspect string of the firing feature.
  # 
  def inspect
    "<Feature::Firing of #{transition.name ? transition.name : transition}>"
  end

  # Firing features are equal if they are of equal PS and refer
  # to the same transition.
  # 
  def == other
    other.is_a? net.State.Feature.Firing and transition == other.transition
  end
end # YPetri::Net::State::Feature::Firing
