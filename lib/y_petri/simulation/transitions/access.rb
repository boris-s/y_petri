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

    # Net's transitions.
    # 
    def tt( transitions=nil )
      transitions( transitions ).sources
    end

    # Net's *ts* transitions.
    # 
    def ts_tt( transitions=nil )
      ts_transitions( transitions ).sources
    end

    # Net's *tS* transitions.
    # 
    def tS_tt( transitions=nil )
      tS_transitions( transitions ).sources
    end


    # Net's *Ts* transitions.
    # 
    def Ts_tt( transitions=nil )
      Ts_transitions( transitions ).sources
    end

    # Net's *TS* transitions.
    # 
    def TS_tt( transitions=nil )
      TS_transitions( transitions ).sources
    end

    # Net's *A* transitions.
    # 
    def A_tt( transitions=nil )
      A_transitions( transitions ).sources
    end

    # Net's *S* transitions.
    # 
    def S_tt( transitions=nil )
      S_transitions( transitions ).sources
    end

    # Net's *s* (non-stoichiometric) transitions.
    # 
    def s_tt( transitions=nil )
      s_transitions( transitions ).sources
    end

    # Net's *T* transitions.
    # 
    def T_tt( transitions=nil )
      T_transitions( transitions ).sources
    end

    # Net's *t* (timeless) transitions.
    # 
    def t_tt transitions=nil
      return transitions.t if transitions.nil?
      transitions.t.subset( transitions )
    end

    # Names of specified transitions.
    # 
    def tn transitions=nil
      tt( transitions ).names( true )
    end

    # Names of specified *ts* transitions.
    # 
    def nts transitions=nil
      ts_tt( transitions ).names( true )
    end

    # Names of specified *tS* transitions.
    # 
    def ntS transitions=nil
      tS_tt( transitions ).names( true )
    end

    # Names of specified *Ts* transitions.
    # 
    def nTs transitions=nil
      Ts_tt( transitions ).names( true )
    end

    # Names of specified *TS* transitions.
    # 
    def nTS transitions=nil
      TS_tt( transitions ).names( true )
    end

    # Names of specified *A* transitions.
    # 
    def nA transitions=nil
      A_tt( transitions ).names( true )
    end

    # Names of specified *S* transitions.
    # 
    def nS transitions=nil
      S_tt( transitions ).names( true )
    end

    # Names of specified *s* transitions.
    # 
    def ns transitions=nil
      s_tt( transitions ).names( true )
    end

    # Names of specified *T* transitions.
    # 
    def nT transitions=nil
      T_tt( transitions ).names( true )
    end

    # Names of specified *t* transitions.
    # 
    def nt transitions=nil
      t_tt( transitions ).names( true )
    end

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

    # Without arguments, returns all the transitions. If arguments are given,
    # they are converted to transitions before being returned.
    # 
    def transitions transitions=nil
      transitions.nil? ? @transitions :
        Transitions().load( transitions.map &method( :transition ) )
    end

    # Simulation's *ts* transtitions. If arguments are given, they must identify
    # *ts* transitions, and are treated as in +#transitions+ method. Note that *A*
    # transitions are not considered eligible *ts* tranisitions for the purposes
    # of this method
    # 
    def ts_transitions transitions=nil
      transitions.nil? ? transitions().ts :
        transitions().ts.subset( transitions transitions )
    end

    # Simulation's *tS* transitions. If arguments are given, they must identify
    # *tS* transitions, and are treated as in +#transitions+ method.
    # 
    def tS_transitions transitions=nil
      transitions.nil? ? transitions().tS :
        transitions().tS.subset( transitions transitions )
    end

    # Simulation's *Ts* transitions. If arguments are given, they must identify
    # *Ts* transitions, and are treated as in +#transitions+ method.
    # 
    def Ts_transitions transitions=nil
      transitions.nil? ? transitions().Ts :
        transitions().Ts.subset( transitions transitions )
    end

    # Simulation's *TS* transitions. If arguments are given, they must identify
    # *TS* transitions, and are treated as in +#transitions+ method.
    # 
    def TS_transitions transitions=nil
      transitions.nil? ? transitions().TS :
        transitions().TS.subset( transitions transitions )
    end

    # Simulation's *A* transitions. If arguments are given, they must identify
    # *A* transitions, and are treated as in +#transitions+ method.
    # 
    def A_transitions transitions=nil
      transitions.nil? ? transitions().A :
      transitions().A.subset( transitions transitions )
    end

    # Simulation's *a* transitions. If argument are given, they must identify
    # *a* transitions, and are treated as in +#transitions+ method.
    # 
    def a_transitions transitions=nil
      transitions.nil? ? transitions().a :
        transitions().a.subset( transitions transitions )
    end

    # Simulation's *S* transitions. If arguments are given, they must identify
    # *S* transitions, and are treated as in +#transitions+ method.
    # 
    def S_transitions transitions=nil
      transitions.nil? ? transitions().S :
        transitions().S.subset( transitions transitions )
    end

    # Simulation's *s* transitions. If arguments are given, they must identify
    # *s* transitions, and are treated as in +#transitions+ method.
    # 
    def s_transitions transitions=nil
      transitions.nil? ? transitions().s :
        transitions().s.subset( transitions transitions )
    end

    # Simulation's *T* transitions. If arguments are given, they must identify
    # *T* transitions, and are treated as in +#transitions+ method.
    # 
    def T_transitions transitions=nil
      transitions.nil? ? transitions().T :
        transitions().T.subset( transitions transitions )
    end

    # Simulation's *t* transitions. If arguments are given, they must identify
    # *t* transitions, and are treated as in +#transitions+ method.
    # 
    def t_transitions transitions=nil
      transitions.nil? ? transitions().t :
        transitions().t.subset( transitions transitions )
    end
  end # Access
end # class YPetri::Simulation::Transitions
