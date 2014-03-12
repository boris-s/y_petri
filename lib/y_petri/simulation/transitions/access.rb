#encoding: utf-8

# Simulation mixin providing access to transitions.
#
class YPetri::Simulation::Transitions
  module Access
    # Does a transition belong to the simulation?
    # 
    def includes_transition?( transition )
      true.tap { begin; transition( transition ); rescue NameError, TypeError
                   return false
                 end }
    end
    alias include_transition? includes_transition?

    # Net's transition.
    # 
    def t( transition )
      transition( transition ).source
    end

    # Makes it so that when "transitions" is abbreviated to "tt", transitions
    # of the underlying net are returned rather than simulation's transition
    # representations.
    # 
    chain Tt: :Transitions,
          tt: :transitions,
          ts_Tt: :ts_Transitions,
          ts_tt: :ts_transitions,
          tS_Tt: :tS_Transitions,
          tS_tt: :tS_transitions,
          Ts_Tt: :Ts_Transitions,
          Ts_tt: :Ts_transitions,
          TS_Tt: :TS_Transitions,
          TS_tt: :TS_transitions,
          A_Tt: :A_Transitions,
          A_tt: :A_transitions,
          S_Tt: :S_Transitions,
          S_tt: :S_transitions,
          s_Tt: :S_Transitions,
          s_tt: :S_transitions,
          T_Tt: :T_Transitions,
          T_tt: :T_transitions,
          t_Tt: :t_Transitions,
          t_tt: :t_transitions,
          &:sources

    # Makes it so that +Tn+/+tn+ means "names of transitions", and that when
    # message "n" + transition_type is sent to the simulation, it returns names
    # of the trasitions of the specified type.
    # 
    chain Tn: :Tt,
          tn: :tt,
          nts: :ts_tt,
          ntS: :tS_tt,
          nTs: :Ts_tt,
          nTS: :TS_tt,
          nA: :A_tt,
          nS: :S_tt,
          ns: :s_tt,
          nT: :T_tt,
          nt: :t_tt do |r| r.names( true ) end

    protected

    # Transition instance identification.
    # 
    def transition( transition )
      begin; Transition().instance( transition ); rescue NameError, TypeError
        begin
          transition = net.transition( transition )
          Transition().instances.find { |t_rep| t_rep.source == transition } || 
            Transition().instance( transition.name )
        rescue NameError, TypeError => msg
          fail TypeError, "Unknown transition instance: #{transition}! (#{msg})"
        end
      end
    end

    # Constructs an instance of @Transitions parametrized subclass. Expects a
    # single array of transitions or transition ids and returns an array of
    # corresponding transition representations in the simulation. Note that the
    # includer of the +Transitions::Access+ module normally overloads
    # :Transitions message in such way, that even without an argument, it does
    # not fil, but returns @Transitions parametrized subclass itself.
    # 
    def Transitions( array )
      Transitions().load array.map &method( :transition )
    end

    # Without arguments, returns all the transition representations in the
    # simulation. Otherwise, it accepts an arbitrary number of elements or
    # element ids as arguments, and returns an array of the corresponding
    # transition representations.
    # 
    def transitions( *transitions )
      return @transitions if transitions.empty?
      Transitions( transitions )
    end

    # Simulation's *ts* transitions. Expects a single array of +ts+ transitions
    # or their ids and returns an array of the corresponding ts transition
    # representations.
    # 
    def ts_Transitions( array )
      transitions.ts.subset( array )
    end

    # Simulation's *ts* transitions. Without arguments, returns all the ts
    # transitions of the simulation. Otherwise, it accepts an arbitrary number
    # of ts transitions or transition ids as arguments, and returns an array of
    # the corresponding ts transitions of the simulation.
    # 
    def ts_transitions( *transitions )
      return transitions().ts if transitions.empty?
      ts_Transitions( transitions )
    end

    # Simulation's *tS* transitions. Expects a single array of +tS+ transitions
    # or their ids and returns an array of the corresponding tS transition
    # representations.
    # 
    def tS_Transitions( array )
      transitions.tS.subset( array )
    end

    # Simulation's *tS* transitions. Without arguments, returns all the tS
    # transitions of the simulation. Otherwise, it accepts an arbitrary number
    # of tS transitions or transition ids as arguments, and returns an array of
    # the corresponding tS transitions of the simulation.
    # 
    def tS_transitions( *transitions )
      return transitions().tS if transitions.empty?
      tS_Transitions( transitions )
    end

    # Simulation's *Ts* transitions. Expects a single array of +Ts+ transitions
    # or their ids and returns an array of the corresponding Ts transition
    # representations.
    # 
    def Ts_Transitions( array )
      transitions.Ts.subset( array )
    end

    # Simulation's *Ts* transitions. Without arguments, returns all the Ts
    # transitions of the simulation. Otherwise, it accepts an arbitrary number
    # of Ts transitions or transition ids as arguments, and returns an array of
    # the corresponding Ts transitions of the simulation.
    # 
    def Ts_transitions( *transitions )
      return transitions().Ts if transitions.empty?
      Ts_Transitions( transitions )
    end

    # Simulation's *TS* transitions. Expects a single array of +TS+ transitions
    # or their ids and returns an array of the corresponding TS transition
    # representations.
    # 
    def TS_Transitions( array )
      transitions.TS.subset( array )
    end

    # Simulation's *TS* transitions. Without arguments, returns all the TS
    # transitions of the simulation. Otherwise, it accepts an arbitrary number
    # of TS transitions or transition ids as arguments, and returns an array of
    # the corresponding TS transitions of the simulation.
    # 
    def TS_transitions( *transitions )
      return transitions().TS if transitions.empty?
      TS_Transitions( transitions )
    end

    # Simulation's *A* transitions. Expects a single array of +A+ transitions
    # or their ids and returns an array of the corresponding A transition
    # representations.
    # 
    def A_Transitions( array )
      transitions.A.subset( array )
    end

    # Simulation's *A* transitions. Without arguments, returns all the A
    # transitions of the simulation. Otherwise, it accepts an arbitrary number
    # of A transitions or transition ids as arguments, and returns an array of
    # the corresponding A transitions of the simulation.
    # 
    def A_transitions( *transitions )
      return transitions().A if transitions.empty?
      A_Transitions( transitions )
    end

    # Simulation's *a* transitions. Expects a single array of +a+ transitions
    # or their ids and returns an array of the corresponding a transition
    # representations.
    # 
    def a_Transitions( array )
      transitions.a.subset( array )
    end

    # Simulation's *a* transitions. Without arguments, returns all the a
    # transitions of the simulation. Otherwise, it accepts an arbitrary number
    # of a transitions or transition ids as arguments, and returns an array of
    # the corresponding a transitions of the simulation.
    # 
    def a_transitions( *transitions )
      return transitions().a if transitions.empty?
      a_Transitions( transitions )
    end

    # Simulation's *S* transitions. Expects a single array of +S+ transitions
    # or their ids and returns an array of the corresponding S transition
    # representations.
    # 
    def S_Transitions( array )
      transitions.S.subset( array )
    end

    # Simulation's *S* transitions. Without arguments, returns all the S
    # transitions of the simulation. Otherwise, it accepts an arbitrary number
    # of S transitions or transition ids as arguments, and returns an array of
    # the corresponding S transitions of the simulation.
    # 
    def S_transitions( *transitions )
      return transitions().S if transitions.empty?
      S_Transitions( transitions )
    end

    # Simulation's *s* transitions. Expects a single array of +s+ transitions
    # or their ids and returns an array of the corresponding s transition
    # representations.
    # 
    def s_Transitions( array )
      transitions.s.subset( array )
    end

    # Simulation's *s* transitions. Without arguments, returns all the s
    # transitions of the simulation. Otherwise, it accepts an arbitrary number
    # of s transitions or transition ids as arguments, and returns an array of
    # the corresponding s transitions of the simulation.
    # 
    def s_transitions( *transitions )
      return transitions().s if transitions.empty?
      s_Transitions( transitions )
    end

    # Simulation's *T* transitions. Expects a single array of +T+ transitions
    # or their ids and returns an array of the corresponding T transition
    # representations.
    # 
    def T_Transitions( array )
      transitions.T.subset( array )
    end

    # Simulation's *T* transitions. Without arguments, returns all the T
    # transitions of the simulation. Otherwise, it accepts an arbitrary number
    # of T transitions or transition ids as arguments, and returns an array of
    # the corresponding T transitions of the simulation.
    # 
    def T_transitions( *transitions )
      return transitions().T if transitions.empty?
      T_Transitions( transitions )
    end

    # Simulation's *t* transitions. Expects a single array of +t+ transitions
    # or their ids and returns an array of the corresponding t transition
    # representations.
    # 
    def t_Transitions( array )
      transitions.t.subset( array )
    end

    # Simulation's *t* transitions. Without arguments, returns all the t
    # transitions of the simulation. Otherwise, it accepts an arbitrary number
    # of t transitions or transition ids as arguments, and returns an array of
    # the corresponding t transitions of the simulation.
    # 
    def t_transitions( *transitions )
      return transitions().t if transitions.empty?
      t_Transitions( transitions )
    end
  end # Access
end # class YPetri::Simulation::Transitions
