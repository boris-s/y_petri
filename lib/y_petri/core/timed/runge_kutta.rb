# encoding: utf-8

# Runge-Kutta method. Like vanilla Euler method, assumes that only T transitions are in the net.
# 
module YPetri::Core::Timed::RungeKutta
  def delta Δt
    # The f below is from the equation state' = f( state )
    f = lambda { |mv| # mv is the marking vector of the free places
      # Here, we first construct a zero marking vector for free places.
      result = simulation.MarkingVector.zero( simulation.free_pp )
      # Here, we get the nonstoichiometric transitions of the simulation.
      nonstoichio_tt = simulation. 
      nonstoichiometric_transitions.each { |t|
        places = t.codomain.free
        inputs = mv.select( t.domain ) # this doesn't work this way
        f = t.function
        output = f.call( *inputs )
        places.each { |p|
          result[p] += output[p] # again, this doesn't work this way
        }
      }
          stoichiometric_transitions.each { |t|
            places = t.codomain.free
            inputs = mv.select( t.domain ) # this doesn't work this way
            f = t.function
            output = f.call( *inputs ) * stoichiometry_vector # this doesn't work this way
            places.each { |p|
              result[p] += output[p]
            }
          }
          # so you see how many selections one has to do if one doesn't
          # construct a specific gadget for the operation, that's why
          # I made those closures, unfortunately I didn't think about
          # higher-order methods yet when making them, and maybe the core
          # should own them instead of the simulation object
          
          return result.to_vector # this doesn't work this way
    }

    # this is supposed to be Runge-Kutta 4th order
    # but how do I get those in-between f values...
    
    y = simulation.state # this must return a vector compatible with the one
                         # returned by f
    
    k1 = f( y )
    k2 = f( y + Δt / 2 * k1 )
    k3 = f( y + Δt / 2 * k2 )
    k4 = f( y + Δt * k3 )

    rslt = Δt / 6 * ( k1 + 2 * k2 + 2 * k3 + k4 )
    return rslt.to_the_kind_of_vector_that_delta_method_should_return
    # which is the vector corresponding to the ordered list of
    # free places of this simulation (here, every core either has a
    # simulation assigned, or is parametrized with simulation, which
    # might be dumb anyway, since core, by its name, should not be that
    # heavily coupled with a simulation, but actually, atm, each core
    # belongs to a specific simulation, so it's OK if it's parametrized
    # with it for now
  end
  alias Δ delta
end # YPetri::Core::Timed::RungeKutta
