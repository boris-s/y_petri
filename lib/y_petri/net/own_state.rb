# encoding: utf-8

# A mixin catering to the net's own state (ie. marking owned by the place
# instances themselves) and its features.
# 
module YPetri::Net::OwnState
  # State owned by the net. This method returns an instance of +Net::State+
  # class (a subclass of Array), containing marking owned by the net's places.
  # 
  def state
    State().new( m )
  end

  # Like #m method, but instead of returning an array of markings, it returns
  # a string of the form "A: 1, B: 2, ...", where A, B, ... are the places
  # and 1, 2, ... their marking. This method is intended to produce output
  # easy to read by humans, while #m method produces regular output (an
  # Array) suitable for further processing. Method accepts arbitrary number
  # of optional arguments, each of which must be a place identifier. If
  # no arguments are given, full marking of the net is described. If
  # arguments are given, only marking of the places identified by the
  # arguments is described.
  #
  def marking *place_ids
    return pp.size == 0 ? "" : marking( *pp ) if place_ids.empty?
    a = [ place_ids.map { |id| place( id ) },
          m( place_ids ) ].transpose
    a.map { |pair| pair.join ": " }.join ', '
  end

  # If no argument is supplied, the method returns the array of the markings
  # owned by the net's places. If an array of place identifiers is supplied,
  # the return value is the array of the markings owned by those places.
  # 
  def m place_ids=nil
    return m( pp ) if place_ids.nil?
    place_ids.map { |id| place( id ).marking }
  end

  # If no argument is supplied, the method resets its places to their default
  # marking. If an array of place identifiers is supplied, only the specified
  # places are reset. Attempts to reset places that have no default marking
  # result in +TypeError+.
  #
  def reset! place_ids=nil
    return reset!( pp ) if place_ids.nil?
    place_ids.map { |id|
      begin
        place( id ).reset_marking
      rescue TypeError => err
        raise TypeError, "Unable to reset the net! " + err.message
      end
    }
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

  # Takes an array of place identifiers, and a named argument +:transitions+,
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
