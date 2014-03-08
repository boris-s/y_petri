#encoding: utf-8

# Place collection for YPetri::Simulation.
#
class YPetri::Simulation::Places < YPetri::Simulation::Elements

  require_relative 'places/types'
  require_relative 'places/free'
  require_relative 'places/clamped'

  ★ Types

  # Pushes a place to the collection.
  # 
  def push place
    p = begin; net.place( place ); rescue NameError, TypeError
          return super place( place )
        end
    super p.name ? Place().new( p, name: p.name ) : Place().new( p )
  end

  # Marking of the place collection in the current simulation.
  # 
  def marking
    simulation.M self
  end

  private

  # Ensures that all the places that are not clamped have their initial marking
  # set. Optional argument :use_default_marking is set to _true_ by default, in
  # which case own default marking of the source places is used if it was not
  # specified when constructing the simulation. If set to _false_, then presence
  # of places with missing initial marking simply raises errors.
  # 
  def complete_initial_marking( use_default_marking: true )
    offenders = reject { |place| ( free + clamped ).include? place }
    fail TypeError, "All places must have default marking or clamp!" unless
      use_default_marking unless offenders.empty?
    offenders.each { |place|
      dm = place.source.default_marking
      fail TypeError, "#{place.source} has no default marking!" if dm.nil?
      simulation.send( :set_initial_marking, place, to: dm )
    }
  end
end # class YPetri::Simulation::Places
