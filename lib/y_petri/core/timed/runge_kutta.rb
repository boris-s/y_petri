# encoding: utf-8

# Runge-Kutta method. Like vanilla Euler method, assumes that only T transitions are in the net.
# 
module YPetri::Core::Timed::RungeKutta
  # Computes delta by Runge-Kutta 4th order method.
  # 
  def delta Δt
    # The f below is from the equation state' = f( state )
    f = lambda do |mv| # mv is the marking vector of the free places
      # Delta from s transitions.
      # TODO: This is only array now. Make it something else. One possibility
      # would be to use simulation's MarkingVector class, but core should
      # actually have its own marking vector class, probably parametrized by
      # the net. It does not matter because alone I won't be able to exhaust
      # all the possibilities.
      delta_s = simulation.MarkingVector.zero( simulation.free_pp )
      # Here, we get the nonstoichiometric transitions of the simulation.
      nonstoichio_tt = simulation.s_tt
      # Now, let's get the delta contribution of the nonstoichio. tt.
      nonstoichio_tt.each { |t|
        domain, codomain = t.domain, t.codomain # transition's domain
        function = t.rate_closure # transition's function
        output = Array function.call( *domain.map { |p| mv.fetch p } )
        codomain.each_with_index do |p, i|
          delta_s.set( p, delta_s.fetch( p ) + output[i] )
        end
        # TODO: The above code is suboptimal, needlessly computing
        # MarkingVector#index and #fetch( place ) each time.
        # The array incrementing might not be the best choice either,
        # and most of all, the whole thing would need to be compiled
        # into assembly language or at least FORTRAN.
      }

      # Delta from S transitions.
      # TODO: (Same remark as for s transitions, see above.)
      delta_S = simulation.MarkingVector.zero( simulation.free_pp )
      # Here, we get the stoichiometric transitions of the simulation
      stoichio_tt = simulation.S_tt
      # Now, let's get the delta contribution of the stoichio. tt.
      stoichio_tt.each { |t|
        domain, codomain = t.domain, t.codomain # transition's domain
        function = t.rate_closure # transition's function
        s = t.stoichiometry
        flux = function.call( *domain.map { |place| mv.fetch place } )
        codomain.each_with_index do |p, i|
          delta_S.set( p, delta_S.fetch( p ) + flux * s[i] )
        end
        # TODO: Again, the above code is suboptimal.
      }

      return delta_s + delta_S
    end

    y = marking_of_free_places

    k1 = f.( y ) # puts "k1 ( = f( y ) ) is #{k1}"
    k2 = f.( y + Δt / 2 * k1 ) # puts "k2 is #{k2}"
    k3 = f.( y + Δt / 2 * k2 ) # puts "k3 is #{k3}"
    k4 = f.( y + Δt * k3 ) # puts "k4 is #{k4}"

    rslt = Δt / 6 * ( k1 + 2 * k2 + 2 * k3 + k4 ) # puts "rslt is #{rslt}"

    return rslt                 # Marking vector of free places
  end
  alias Δ delta

  def step! Δt=simulation.step
    # TODO: Thus far, runge_kutta method is an exception in the core in
    # that it works with core's own state. (Core used to work with
    # simulation's state before and rely on the simulation to provide
    # state increment and assign closures.) This is how whole core should
    # work.
    increment_marking_of_free_places Δ( Δt )
    increment_time! Δt
    alert_user! marking_of_free_places
  end

  def increment_marking_of_free_places by
    # TODO: Same remark as above.
    @marking_of_free_places += by
  end

  def increment_time! by
    # TODO: Once other timed methods than runge_kutta are reasonable, this
    # should be moved to core/timed.rb
    @time += by
  end

  def reset_time! to=0.0
    # TODO: Once other timed methods than runge_kutta are reasonable, this
    # should be moved to core/timed.rb
    @time = to
  end

  def set_user_alert_closure &block
    # TODO: Core's runge_kutta method is special for now, and even
    # simulation recognizes that. With runge_kutta method, core uses
    # single @user_alert_closure which it calls whenever the state
    # of the core progresses. It is the business of the user to supply,
    # before using the core, that does what the user wants. It is also
    # imaginable that different core's modes of operation would have
    # different sensitivity with regard to alerting the user, but for now,
    # the user is alerted whenever anything happens at all.
    @user_alert_closure = block
  end

  def alert_user! object
    # TODO: As soon as more core's method begin relying on core's own state,
    # this method will be moved to Core module.
    @user_alert_closure.call( object )
  end
end # YPetri::Core::Timed::RungeKutta
