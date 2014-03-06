# encoding: utf-8

# A feature of a Petri net.
#
class YPetri::Net::State::Feature
  require_relative 'feature/marking'
  require_relative 'feature/firing'
  require_relative 'feature/gradient'
  require_relative 'feature/flux'
  require_relative 'feature/delta'
  require_relative 'feature/assignment'

  class << self
    def parametrize parameters
      Class.new( self ).tap do |ç|
        parameters.each_pair do |ß, val|
          ç.define_singleton_method ß do val end
        end
        sç = ç.State
        ç.instance_variable_set :@Marking, Marking.parametrize( State: sç )
        ç.instance_variable_set :@Firing, Firing.parametrize( State: sç )
        ç.instance_variable_set :@Gradient, Gradient.parametrize( State: sç )
        ç.instance_variable_set :@Flux, Flux.parametrize( State: sç )
        ç.instance_variable_set :@Delta, Delta.parametrize( State: sç )
        ç.instance_variable_set :@Assignment, Assignment.parametrize( State: sç )
      end
    end

    delegate :net, to: "State()"

    # Marking feature constructor. Takes a single place identifying argument.
    # 
    def Marking id=L!
      return @Marking if id.local_object?
      case id
      when Marking() then id
      when Marking then Marking().of( id.place )
      else Marking().of( id ) end # assume place
    end

    # Firing feature constructor. Takes a single argument, which must identify
    # an S transition (nonstoichiometric transitions don't have firing, though
    # they do have action.)
    # 
    def Firing id=L!
      return @Firing if id.local_object?
      case id
      when Firing() then id
      when Firing then Firing().of( id.transition )
      else Firing().of( id ) end # assume transition
    end

    # Gradient feature constructor. Takes a single ordered argument, which must
    # identify a place, and an optional named argument +:transitions+, which must
    # contain an array of T transition identifyers (gradient is defined as time
    # derivative, so timeless transitions are not eligible). If not given, the
    # gradient feature is constructed with respect to all net's T transitions.
    # 
    def Gradient id=L!, transitions: net.T_tt
      return @Gradient if id.local_object?
      case id
      when Gradient() then id
      when Gradient then
        Gradient().of( id.place, transitions: id.transitions )
      else
        Gradient().of( id, transitions: transitions ) # assume place
      end
    end

    # Flux feature constructor. Takes a single argument, which must identify
    # a TS transition. Flux is defined as time derivative of firing.
    # 
    def Flux id=L!
      return @Flux if id.local_object?
      case id
      when Flux() then id
      when Flux then Flux().of( id.transition )
      else Flux().of( id ) end # assume transition
    end

    # Delta feature constructor. Takes a single ordered argument, which must
    # identify a place, and an optional named argument +:transitions+, which
    # must contain an array of transition idetifyers. If not given, the delta
    # feature is constructed with respect to all net's transitions.
    #
    # Furthermore, if the +:transitions+ argument is given, the transitions must
    # be either all timeless, or all timed. Delta features are thus of 2 kinds:
    # timed and timeless (can be inquired via +#timed?+). When used to extract
    # values from the target object, timeless delta merely returns a value, while
    # timed returns unary closure waiting for Δt argument to return delta for
    # that Δt (if you want the rate directly, use a gradient feature).
    # 
    def Delta id=L!, transitions: net.tt
      return @Delta if id.local_object?
      case id
      when Delta() then id
      when Delta then
        Delta().of( id.place, transitions: id.transitions )
      else
        Delta().of( id, transitions: transitions )
      end # assume place
    end

    # Assignment feature constructor. Takes a single ordered argument, which
    # must identify a place, and an optional argument +:transition+, which
    # must identify a single A (assignment) transition. The feature extracts
    # the assignment action from the transition to the place. If the
    # +:transition+ named argument is not given, the place's upstream arcs
    # must contain exactly one A transition.
    # 
    def Assignment id=L!, transition: L!
      return @Assignment if id.local_object? && transition.local_object?
      case id
      when Assignment() then id
      when Assignment then
        Assignment().to( id.place, transition: id.transition )
      else
        fail ArgumentError, "No place given!" if id.local_object?
        if transition.local_object? then
          Assignment().to( id )
        else
          Assignment().to( id, transition: transition )
        end
      end
    end

    # Takes a single argument, and infers a feature from it in the following way:
    # A +net.State.Feature+ instance is returned unchanged. Place or place id is
    # converted to a marking feature. Otherwise, the argument is treated as a
    # transition, and is converted to either a flux feature (if timed), or a
    # firing feature (if timeless).
    # 
    def infer_from_element( arg )
      case arg
      when self then return arg
      when Marking then return Marking().of( arg.place )
      when Firing then return Firing().of( arg.transition )
      when Gradient then
        return Gradient().of( arg.place, transitions: arg.transitions )
      when Flux then return Flux().of( arg.transition )
      when Delta then
        return Delta().of( arg.place, transitions: arg.transitions )
      when Assignment then
        return Assignment().to( arg.place, transitions: arg.transition )
      else # treated as a place or transition id
        e, type = begin
                    [ net.place( arg ), :place ]
                  rescue TypeError, NameError
                    [ net.transition( arg ), :transition ]
                  end
      end
      case type
      when :place then Marking( e )
      when :transition then
        fail TypeError, "Flux / firing features can only be auto-inferred " +
          "from S transitions! (#{element} was given)" unless e.S?
        e.timed? ? Flux( e ) : Firing( e )
      end
    end
  end # class << self

  delegate :net,
           :State,
           to: "self.class"
end # class YPetri::Net::State::Feature
