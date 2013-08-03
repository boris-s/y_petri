# encoding: utf-8

# A collection of values for a given set of state features.
# 
class YPetri::Net::State::Features::Record < Array
  class << self
    delegate :State,
             :net,
             to: "Features()"

    # Construcs a new Record object from a given collection of values.
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

  # Given a set of marking clamps complementary...
  # 
  def reconstruct marking_clamps: {}, **settings
    net.simulation marking_clamps: {}, marking: marking, **settings
  end

  # Returns the marking of a given place, or array of places (must be in the
  # record). If no argument is given, marking of all the places in the record
  # is returned.
  # 
  def marking pl=nil
    return marking( features.marking ) if pl.nil?
    case pl
    when Array then pl.map { |id| marking net.place( id ) }
    else fetch( net.State.Marking.of pl ) end
  end

  # Returns the flux of a given transition, or array of transitions (must be in
  # the record). If no argument is given, flux of all the transitions in the
  # record is returned.
  # 
  def flux tr=nil
    return flux( features.flux ) if tr.nil?
    case tr
    when Array then tr.map { |id| flux net.transition( id ) }
    else fetch( net.State.Flux.of tr ) end
  end

  # Returns the firing of a given transition, or array of transitions (must be
  # in the record). If no argument is given, firing of all the transitions in
  # the record is returned.
  # 
  def firing tr=nil
    return firing( features.firing ) if tr.nil?
    case tr
    when Array then tr.map { |id| firing net.transition( id ) }
    else fetch( net.State.Firing.of tr ) end
  end

  # Returns the gradient of a given place, or array of places, contributed by
  # a given set of transitions (the feature must be in the record). If the
  # place-specifying argument is not given, values for all the matching
  # gradient features are returned.
  # 
  def gradient pl=nil, transitions: nil
    if pl.nil? then
      return gradient( features.gradient ) if transitions.nil?
      gradient( features.gradient.select do |f|
                  f.transitions == transitions.map { |t| net.transition t }
                end )
    else
      return gradient( pl, transitions: net.T_tt ) if transitions.nil?
      case pl
      when Array then
        pl.map { |id| gradient id, transitions: transitions }
      else
        fetch( net.State.Gradient.of pl, transitions: net.T_tt( transitions ) )
      end
    end
  end

  # Returns the delta of a given place, or array of places, contributed by a
  # given set of transitions (the feature must be in the record). If the
  # place-specifying argument is not given, values for all the matching delta
  # features are returned.
  # 
  def delta pl=nil, transitions: nil
    if pl.nil? then
      return delta( features.delta ) if transitions.nil?
      delta( features.delta.select do |f|
               f.transitions == transitions.map { |t| net.transition t }
             end )
    else
      return delta( pl, transitions: net.tt ) if transitions.nil?
      case pl
      when Array then
        pl.map { |id| delta id, transitions: transitions }
      else
        fetch( net.State.Delta.of pl, transitions: net.tt( transitions ) )
      end
    end
  end
end # class YPetri::Net::State::Features::Record
