#encoding: utf-8

# Simulation mixin providing access to transitions.
#
class YPetri::Simulation::Transitions
  module Access
    # Does a transition belong to the simulation?
    # 
    def includes_transition?( id )
      true.tap { begin; transition( id )
                 rescue NameError, TypeError
                   return false
                 end }
    end
    alias include_transition? includes_transition?

    # Net's transition.
    # 
    def t( id )
      transition( id ).source
    end

    # Net's transitions.
    # 
    def tt( ids=nil )
      transitions( ids ).sources
    end

    # Net's *ts* transitions.
    # 
    def ts_tt( ids=nil )
      ts_transitions( ids ).sources
    end

    # Net's *tS* transitions.
    # 
    def tS_tt( ids=nil )
      tS_transitions( ids ).sources
    end


    # Net's *Ts* transitions.
    # 
    def Ts_tt( ids=nil )
      Ts_transitions( ids ).sources
    end

    # Net's *TS* transitions.
    # 
    def TS_tt( ids=nil )
      TS_transitions( ids ).sources
    end

    # Net's *A* transitions.
    # 
    def A_tt( ids=nil )
      A_transitions( ids ).sources
    end

    # Net's *S* transitions.
    # 
    def S_tt( ids=nil )
      S_transitions( ids ).sources
    end

    # Net's *s* (non-stoichiometric) transitions.
    # 
    def s_tt( ids=nil )
      s_transitions( ids ).sources
    end

    # Net's *T* transitions.
    # 
    def T_tt( ids=nil )
      T_transitions( ids ).sources
    end

    # Net's *t* (timeless) transitions.
    # 
    def t_tt ids=nil
      return transitions.t if ids.nil?
      transitions.t.subset( ids )
    end

    # Names of specified transitions.
    # 
    def tn ids=nil
      tt( ids ).names
    end

    # Names of specified *ts* transitions.
    # 
    def nts ids=nil
      ts_tt( ids ).names( true )
    end

    # Names of specified *tS* transitions.
    # 
    def ntS ids=nil
      tS_tt( ids ).names( true )
    end

    # Names of specified *Ts* transitions.
    # 
    def nTs ids=nil
      Ts_tt( ids ).names( true )
    end

    # Names of specified *TS* transitions.
    # 
    def nTS ids=nil
      TS_tt( ids ).names( true )
    end

    # Names of specified *A* transitions.
    # 
    def nA ids=nil
      A_tt( ids ).names( true )
    end

    # Names of specified *S* transitions.
    # 
    def nS ids=nil
      S_tt( ids ).names( true )
    end

    # Names of specified *s* transitions.
    # 
    def ns ids=nil
      s_tt( ids ).names( true )
    end

    # Names of specified *T* transitions.
    # 
    def nT ids=nil
      T_tt( ids ).names( true )
    end

    # Names of specified *t* transitions.
    # 
    def nt ids=nil
      t_tt( ids ).names( true )
    end

    protected

    # Transition instance identification.
    # 
    def transition( id )
      begin
        Transition().instance( id )
      rescue NameError, TypeError
        begin
          tr = net.transition( id )
          Transition().instances.find { |t_rep| t_rep.source == tr } || 
            Transition().instance( tr.name )
        rescue NameError, TypeError => msg
          raise TypeError, "The argument #{id} does not identify a " +
            "transition instance! (#{msg})"
        end
      end
    end

    # Without arguments, returns all the transitions. If arguments are given,
    # they are converted to transitions before being returned.
    # 
    def transitions ids=nil
      return @transitions if ids.nil?
      Transitions().load( ids.map { |id| transition id } )
    end

    # Simulation's *ts* transtitions. If arguments are given, they must identify
    # *ts* transitions, and are treated as in +#transitions+ method. Note that *A*
    # transitions are not considered eligible *ts* tranisitions for the purposes
    # of this method.
    # 
    def ts_transitions ids=nil
      return transitions.ts if ids.nil?
      transitions.ts.subset( transitions ids )
    end

    # Simulation's *tS* transitions. If arguments are given, they must identify
    # *tS* transitions, and are treated as in +#transitions+ method.
    # 
    def tS_transitions ids=nil
      return transitions.tS if ids.nil?
      transitions.tS.subset( transitions ids )
    end

    # Simulation's *Ts* transitions. If arguments are given, they must identify
    # *Ts* transitions, and are treated as in +#transitions+ method.
    # 
    def Ts_transitions ids=nil
      return transitions.Ts if ids.nil?
      transitions.Ts.subset( transitions ids )
    end

    # Simulation's *TS* transitions. If arguments are given, they must identify
    # *TS* transitions, and are treated as in +#transitions+ method.
    # 
    def TS_transitions ids=nil
      return transitions.TS if ids.nil?
      transitions.TS.subset( transitions ids )
    end

    # Simulation's *A* transitions. If arguments are given, they must identify
    # *A* transitions, and are treated as in +#transitions+ method.
    # 
    def A_transitions ids=nil
      return transitions.A if ids.nil?
      transitions.A.subset( transitions ids )
    end

    # Simulation's *a* transitions. If argument are given, they must identify
    # *a* transitions, and are treated as in +#transitions+ method.
    # 
    def a_transitions ids=nil
      return transitions.a if ids.nil?
      transitions.a.subset( transitions ids )
    end

    # Simulation's *S* transitions. If arguments are given, they must identify
    # *S* transitions, and are treated as in +#transitions+ method.
    # 
    def S_transitions ids=nil
      return transitions.S if ids.nil?
      transitions.S.subset( transitions ids )
    end

    # Simulation's *s* transitions. If arguments are given, they must identify
    # *s* transitions, and are treated as in +#transitions+ method.
    # 
    def s_transitions ids=nil
      return transitions.s if ids.nil?
      transitions.s.subset( transitions ids )
    end

    # Simulation's *T* transitions. If arguments are given, they must identify
    # *T* transitions, and are treated as in +#transitions+ method.
    # 
    def T_transitions ids=nil
      return transitions.T if ids.nil?
      transitions.T.subset( transitions ids )
    end

    # Simulation's *t* transitions. If arguments are given, they must identify
    # *t* transitions, and are treated as in +#transitions+ method.
    # 
    def t_transitions ids=nil
      return transitions.t if ids.nil?
      transitions.t.subset( transitions ids )
    end
  end # Access
end # class YPetri::Simulation::Transitions
