#encoding: utf-8

# A mixin catering to the net's own state (ie. marking owned by the place
# instances themselves) and its features.
# 
module YPetri::Net::OwnState
  # State owned by the net. More precisely, an instance of the Net::State class,
  # which is an Array subclass, containing the markings owned by the net's
  # places as its elements.
  # 
  def state
    State().new( marking )
  end

  # If no argument is supplied, the method returns the array of the markings
  # owned by the net's places. If an array of place identifiers is supplied,
  # the return value is the array of the markings owned by those places.
  #
  def marking place_ids=nil
    return marking( pp ) if place_ids.nil?
    place_ids.map { |id| place( id ).marking }
  end

  # Takes an array of tS transition identifiers as an optional argument, and
  # returns the array of their firing under current net state. If no argument
  # is supplied, the net is required to contain no TS transtions, and the
  # method returns the array of firing of all net's tS transitions.
  #
  def firing transition_ids=nil
    if transition_ids.nil? then
      fail TypeError, "Method #firing with no arguments is ambiguous for " +
        "nets with TS transitions!" if timed?
      firing tS_tt
    else
      transition_ids.map { |id| tS_transition( id ).firing }
    end
  end

  # Takes an array of TS transition identifiers as an optional argument, and
  # returns the array of their fluxes under current net state. If no argument
  # is supplied, the array of fluxes of all net's TS transitions is returned.
  #
  def flux transition_ids=nil
    return flux TS_tt() if transition_ids.nil?
    transition_ids.map { |id| TS_transition( id ).flux }
  end

  # Takes an array of place identifiers, and a named argument +:transitions+,
  # and returns the array of the place gradient contribution by the indicated
  # transitions. The +:transitions+ argument defaults to all the transitions,
  # place identifiers default to all the places. The net must be timed.
  # 
  #
  def gradient place_ids=pp, transitions: tt
    fail NotImplementedError
  end

  # Takes an array of place identifier, and a named argument +:transitions+,
  # and returns the array of the place delta contribution by the indicated
  # transitions.
  #
  def delta place_ids=nil, transitions: tt
    fail NotImplementedError
  end

  # Takes an array of A transition identifiers as an optional argument, and
  # returns the array of their actions under current net state. If no argument
  # is supplied, the array of assignments of all net's A transitions is returned.
  #
  def assignment transition_ids=nil
    return assigment A_tt() if transition_ids.nil?
    transition_ids.map { |id| A_transition( id ).action }
  end
end # module YPetri::Net::OwnState
