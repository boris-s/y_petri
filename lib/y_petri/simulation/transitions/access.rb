#encoding: utf-8

# Simulation mixin providing access to transitions.
#
class YPetri::Simulation::Transitions
  module Access
    # Transition instance identification.
    # 
    def transition( id )
      begin
        Transition().instance( id )
      rescue NameError, TypeError
        begin
          puts 'here'
          tr = net.transition( id )
          Transition().instances.find { |t_rep| t_rep.source == tr } || 
            Transition().instance( tr.name )
        rescue NameError, TypeError => msg
          raise TypeError, "The argument #{id} does not identify a " +
            "transition instance! (#{msg})"
        end
      end
    end

    # Does a transition belong to the simulation?
    # 
    def includes_transition?( id )
      true.tap { begin; transition( id )
                 rescue NameError, TypeError
                   return false
                 end }
    end
    alias include_transition? includes_transition?

    # Without arguments, returns all the transitions. If arguments are given,
    # they are converted to transitions before being returned.
    # 
    def transitions ids=nil
      return @transitions if ids.nil?
      Transitions().load( ids.map { |id| transition id } )
    end

    # Transitions' names. Arguments, if any, are treated as in +#tranistions+ method.
    # 
    def tn ids=nil
      transitions( ids ).names
    end

    # Simulation's *ts* transtitions. If arguments are given, they must identify
    # *ts* transitions, and are treated as in +#transitions+ method. Note that *A*
    # transitions are not considered eligible *ts* tranisitions for the purposes
    # of this method.
    # 
    def ts_transitions ids=nil
      return transitions.ts if ids.nil?
      transitions.ts.subset( ids )
    end

    # Names of *ts* transitions. Arguments are handled as with +#ts_transitions+.
    # 
    def nts ids=nil
      ts_transitions( ids ).names( true )
    end

    # Simulation's *tS* transitions. If arguments are given, they must identify
    # *tS* transitions, and are treated as in +#transitions+ method.
    # 
    def tS_transitions ids=nil
      return transitions.tS if ids.nil?
      transitions.tS.subset( ids )
    end

    # Names of *tS* transitions. Arguments are handled as with +#tS_transitions+.
    # 
    def ntS ids=nil
      tS_transitions( ids ).names( true )
    end

    # Simulation's *Ts* transitions. If arguments are given, they must identify
    # *Ts* transitions, and are treated as in +#transitions+ method.
    # 
    def Ts_transitions ids=nil
      return transitions.Ts if ids.nil?
      transitions.Ts.subset( ids )
    end

    # Names of *Ts* transitions. Arguments are handled as with +#tS_transitions+.
    # 
    def nTs ids=nil
      Ts_transitions( ids ).names( true )
    end

    # Simulation's *TS* transitions. If arguments are given, they must identify
    # *TS* transitions, and are treated as in +#transitions+ method.
    # 
    def TS_transitions ids=nil
      return transitions.TS if ids.nil?
      transitions.TS.subset( ids )
    end

    # Names of *TS* transitions. Arguments are handled as with +#TS_transitions+.
    # 
    def nTS ids=nil
      TS_transitions( ids ).names( true )
    end

    # Simulation's *A* transitions. If arguments are given, they must identify
    # *A* transitions, and are treated as in +#transitions+ method.
    # 
    def A_transitions ids=nil
      return transitions.A if ids.nil?
      transitions.A.subset( ids )
    end

    # Names of *A* transitions. Arguments are handled as with +#A_transitions+.
    # 
    def nA ids=nil
      A_transitions( ids ).names( true )
    end

    # Simulation's *S* transitions. If arguments are given, they must identify
    # *S* transitions, and are treated as in +#transitions+ method.
    # 
    def S_transitions ids=nil
      return transitions.S if ids.nil?
      transitions.S.subset( ids )
    end

    # Names of *S* transitions. Arguments are handled as with +#S_transitions+.
    # 
    def nS ids=nil
      S_transitions( ids ).names( true )
    end

    # Simulation's *s* transitions. If arguments are given, they must identify
    # *s* transitions, and are treated as in +#transitions+ method.
    # 
    def s_transitions ids=nil
      return transitions.s if ids.nil?
      transitions.s.subset( ids )
    end

    # Names of *s* transitions. Arguments are handled as with +#s_transitions+.
    # 
    def ns ids=nil
      s_transitions( ids ).names( true )
    end
  end # Access
end # class YPetri::Simulation::Transitions
