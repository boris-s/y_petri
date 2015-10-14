# encoding: utf-8

# Runge-Kutta method. Like vanilla Euler method, assumes that only T transitions are in the net.
# 
module YPetri::Core::Timed::RungeKutta
  def delta Δt
    puts "Hello from Δt method."
    # The f below is from the equation state' = f( state )
    f = lambda { |mv| # mv is the marking vector of the free places
      # Here, we initialize the delta contribution of nonstoichiometric
      # transitions as a zero marking vector for free places.
      delta_s = Array.new( simulation.free_pp.size, 0 )
      # Here, we get the nonstoichiometric transitions of the simulation.
      nonstoichio_tt = simulation.s_tt
      # Now, let's get the delta contribution of the nonstoichio. tt.
      nonstoichio_tt.each { |t|
        domain = t.domain         # transition's domain
        codomain = t.codomain     # transition's codomain
        function = t.rate_closure # transition's function
        output = Array function.call( *domain.map { |place| mv.fetch place } )
        codomain.each_with_index do |place, i|
          delta_s[ delta_s.index( place ) ] += output[i]
        end
        # The above code is suboptimal, needlessly computing
        # MarkingVector#index and #fetch( place ) each time.
        # The array incrementing might not be the best choice either,
        # and most of all, the whole thing would need to be compiled
        # into assembly language or at least FORTRAN.
      }

      # Here, we initialize the delta contribution of stoichiometric
      # transitions as a zero marking vector for free places.
      delta_S = Array.new( simulation.free_pp.size, 0 )
      # Here, we get the stoichiometric transitions of the simulation
      stoichio_tt = simulation.s_tt
      # Now, let's get the delta contribution of the stoichio. tt.
      stoichio_tt.each { |t|
        domain = t.domain         # transition's domain
        codomain = t.codomain     # transition's codomain
        function = t.rate_closure # transition's function
        s = function.stoichiometry_vector
        flux = function.call( *domain.map { |place| mv.fetch place } )
        codomain.each_with_index do |place, i|
          delta_S[ delta_S.index( place ) ] += flux * s[i]
        end
        # Again, the above code is suboptimal.
      }
      # The resulting delta is the sum of the two vectors
      result = simulation.free_pp >> delta_s.zip( delta_S ).map { |a, b| a + b }
      return simulation.MarkingVector[ result ]
      # TODO: It seems a good idea to work with Matrix or NMatrix on the long
      # run, but at the moment, it might be faster to stick with array.
    }

    # this is supposed to be Runge-Kutta 4th order
    # but how do I get those in-between f values...

    y = @marking_free

    puts "Current free marking vector is #{@marking_free.to_a.join ', '}"

    k1 = f.( y )

    puts "k1 ( = f( y ) ) is #{k1}"
    k2 = f.( y + Δt / 2 * k1 )
    puts "k2 is #{k2}"
    k3 = f.( y + Δt / 2 * k2 )
    puts "k3 is #{k3}"
    k4 = f.( y + Δt * k3 )
    puts "k4 is #{k4}"

    rslt = Δt / 6 * ( k1 + 2 * k2 + 2 * k3 + k4 )
    puts "rslt is #{rslt}"

    return rslt                 # Marking vector of free places
  end
  alias Δ delta

  def step! Δt=simulation.step
    increment_marking_free Δ( Δt )
    increment_time! Δt
    simulation.recorder.alert
  end
end # YPetri::Core::Timed::RungeKutta
