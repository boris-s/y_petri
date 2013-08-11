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
    features.map { |f| fetch( f ).round( precision ) }
  end

  # Pretty prints the record with feature names.
  # 
  def pretty_print gap: 20, precision: 4
    hsh = features.labels >> dump
    lmax = hsh.keys
      .map( &:to_s ).map( &:size ).max
    rmax = hsh.values
      .map { |n| "%.#{precision}e" % n }
      .map( &:to_s ).map( &:size ).max
    lgap = gap / 2
    rgap = gap - lgap
    puts hsh.map do |key, val|
      "%- #{lmax+lgap+1}s%#{rmax+rgap+1}.#{precision}e" % [ key, val ]
    end
    return nil
  end

  # Returns an identified feature, or fails.
  # 
  def fetch feature
    super begin
            Integer( feature )
          rescue TypeError
            features.index State().feature( feature )
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
    msg = "Marking clamps given in the argument taken together with this " +
      "record's markings must complete the full state of the net!"
    fail TypeError, msg unless
      features.marking.map( &:place ) + net.places( cc.keys ) == net.places
    State().new net.places.map do |place|
      begin; cc.fetch place; rescue IndexError; fetch marking( place ) end
    end
  end

  # Given a set of marking clamps complementary to the marking features of this
  # record, reconstructs a Simulation instance with the corresponding state.
  # If the net is timed, or if the construction of the simulation from the net
  # has need for any special settings, these must be supplied to this method.
  # (Timed nets eg. require +:time+ named argument for successful construction.)
  # 
  def reconstruct marking_clamps: {}, **settings
    net.simulation marking_clamps: {}, marking: marking, **settings
  end

  # Expects a marking feature identifier (place identifier or Marking instance),
  # and returns the value for that feature in this record. If an array of
  # marking feature identifiers is supplied, it is mapped to the array of
  # corresponding values. If no argument is given, values from this record for
  # all the present marking features are returned.
  # 
  def marking id=nil
    return marking( features.marking ) if id.nil?
    case id
    when Array then id.map { |id| marking id }
    else fetch( features.marking id ) end
  end

  # Expects a flux feature identifier (transition identifier or Flux instance),
  # and returns the value for that feature in this record. If an array of flux
  # feature identifiers is supplied, it is mapped to the array of corresponding
  # values. If no argument is given, values from this record for all the present
  # flux features are returned.
  # 
  def flux id=nil
    return flux( features.flux ) if id.nil?
    case id
    when Array then id.map { |id| flux net.transition( id ) }
    else fetch( features.flux id ) end
  end

  # Expects a firing feature identifier (transition identifier or Firing
  # instance), and returns the value for that feature in this record. If an
  # array of firing feature identifiers is supplied, it is mapped to the array
  # of corresponding values. If no argument is given, values from this record
  # for all the present flux features are returned.
  # 
  def firing id=nil
    return firing( features.firing ) if id.nil?
    case id
    when Array then id.map { |id| firing net.transition( id ) }
    else fetch( features.firing id ) end
  end

  # Expects a gradient feature identifier (place identifier, or Gradient
  # instance), qualified by an array of transitions (named argument
  # +:transitions+, defaults to all timed transitions in the net), and returns
  # the value for that feature in this record. If an array of gradient feature
  # identifiers is supplied, it is mapped to the array of corresponding values.
  # If no gradient feature identifier is given, values from this record for all
  # the present gradient features are returned.
  # 
  def gradient id=nil, transitions: nil
    if id.nil? then
      return gradient( features.gradient ) if transitions.nil?
      gradient( features.gradient.select do |f|
                  f.transitions == transitions.map { |t| net.transition t }
                end )
    else
      return gradient( id, transitions: net.T_tt ) if transitions.nil?
      case id
      when Array then
        pl.map { |id| gradient id, transitions: transitions }
      else
        fetch( features.gradient id, transitions: transitions )
      end
    end
  end

  # Expects a gradient feature identifier (place identifier, or Delta instance),
  # qualified by an array of transitions (named argument +:transitions+,
  # defaults to all timed transitions in the net), and returns the value for
  # that feature in this record. If an array of delta feature identifiers is
  # supplied, it is mapped to the array of corresponding values. If no delta
  # feature identifier is given, values from this record for all the present
  # delta features are returned.
  # 
  def delta pl=nil, transitions: nil
    if id.nil? then
      return delta( features.delta ) if transitions.nil?
      delta( features.delta.select do |f|
               f.transitions == transitions.map { |t| net.transition t }
             end )
    else
      return delta( id, transitions: net.tt ) if transitions.nil?
      case id
      when Array then
        id.map { |id| delta id, transitions: transitions }
      else
        fetch( features.delta id, transitions: net.tt( transitions ) )
      end
    end
  end
end # class YPetri::Net::State::Features::Record
