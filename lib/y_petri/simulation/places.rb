#encoding: utf-8

require_relative 'places/types'
require_relative 'places/free'
require_relative 'places/clamped'

# Place collection for YPetri::Simulation.
#
class YPetri::Simulation::Places
  include Types

  # Pushes a place to the collection.
  # 
  def push place
    p = begin
          net.place( place )
        rescue NameError, TypeError
          return super place( place )
        end
    super p.name ? Place().new( p, name: p.name ) : Place().new( p )
  end

  # Correspondence matrix to another set of places.
  # 
  def correspondence_matrix places
    Matrix.correspondence_matrix self, places( places )
  end

  # Ensures that all the places that are not clamped have their initial marking
  # set. Optional argument :use_default_marking is set to _true_ by default, in
  # which case own default marking of the source places is used if it was not
  # specified when constructing the simulation. If set to _false_, then presence
  # of places with missing initial marking simply raises errors.
  # 
  def complete_initial_marking( use_default_marking: true )
    missing = reject { |pl| ( free + clamped ).include? pl }
    unless use_default_marking
      fail TypeError, "All places must have default marking or clamp!" unless
        missing.empty?
    end
    missing.each { |pl|
      dflt = pl.source.default_marking
      fail TypeError, "Source's default marking is missing (nil)!" if dflt.nil?
      simulation.send :set_initial_marking, { of: pl, to: dflt }
    }
  end
end # class YPetri::Simulation::Places
