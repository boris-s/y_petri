#encoding: utf-8

# Mixin providing collection of places to the Simulation class.
#
class YPetri::Simulation::TransitionRepresentation
  module Collections
    # Without arguments, returns all the transitions. If arguments are given, they
    # are converted to transitions before being returned.
    # 
    def transitions *ids
      return @transitions if ids.empty?
      Transitions().load( ids.map { |id| transition( id ) } )
    end
    
    # Transitions' names. Arguments, if any, are treated as in +#tranistions+ method.
    # 
    def tn *ids
      transitions( *ids ).names
    end
    
    # Simulation's *ts* transtitions. If arguments are given, they must identify
    # *ts* transitions, and are treated as in +#transitions+ method. Note that *A*
    # transitions are not considered eligible *ts* tranisitions for the purposes
    # of this method.
    # 
    def ts_transitions *ids
      return transitions.ts if ids.empty?
      transitions.ts.subset( *ids )
    end
    
    # Names of *ts* transitions. Arguments are handled as with +#ts_transitions+.
    # 
    def names_of_ts *ids
      ts_transitions( *ids ).names( true )
    end
    alias n_ts names_of_ts
    
    # Simulation's *tS* transitions. If arguments are given, they must identify
    # *tS* transitions, and are treated as in +#transitions+ method.
    # 
    def tS_transitions *ids
      return transitions.tS if ids.empty?
      transitions.tS.subset( *ids )
    end
    
    # Names of *tS* transitions. Arguments are handled as with +#tS_transitions+.
    # 
    def names_of_tS *ids
      tS_transitions( *ids ).names( true )
    end
    alias n_tS names_of_tS
    
    # Simulation's *Ts* transitions. If arguments are given, they must identify
    # *Ts* transitions, and are treated as in +#transitions+ method.
    # 
    def Ts_transitions *ids
      return transitions.Ts if ids.empty?
      transitions.Ts.subset( *ids )
    end
    
    # Names of *Ts* transitions. Arguments are handled as with +#tS_transitions+.
    # 
    def names_of_Ts *ids
      Ts_transitions( *ids ).names( true )
    end
    alias n_Ts names_of_Ts
    
    # Simulation's *TS* transitions. If arguments are given, they must identify
    # *TS* transitions, and are treated as in +#transitions+ method.
    # 
    def TS_transitions *ids
      return transitions.TS if ids.empty?
      transitions.TS.subset( *ids )
    end
    
    # Names of *TS* transitions. Arguments are handled as with +#TS_transitions+.
    # 
    def names_of_TS *ids
      TS_transitions( *ids ).names( true )
    end
    alias n_TS names_of_TS
    
    # Simulation's *A* transitions. If arguments are given, they must identify
    # *A* transitions, and are treated as in +#transitions+ method.
    # 
    def A_transitions *ids
      return transitions.A if ids.empty?
      transitions.A.subset( *ids )
    end
    
    # Names of *A* transitions. Arguments are handled as with +#A_transitions+.
    # 
    def names_of_A *ids
      A_transitions( *ids ).names( true )
    end
    alias n_A names_of_A
    
    # Simulation's *S* transitions. If arguments are given, they must identify
    # *S* transitions, and are treated as in +#transitions+ method.
    # 
    def S_transitions *ids
      return transitions.S if ids.empty?
      transitions.S.subset( *ids )
    end
    
    # Names of *S* transitions. Arguments are handled as with +#S_transitions+.
    # 
    def names_of_S *ids
      S_transitions( *ids ).names( true )
    end
    alias n_S names_of_S
    
    # Simulation's *s* transitions. If arguments are given, they must identify
    # *s* transitions, and are treated as in +#transitions+ method.
    # 
    def s_transitions *ids
      return transitions.s if ids.empty?
      transitions.s.subset( *ids )
    end
    
    # Names of *s* transitions. Arguments are handled as with +#s_transitions+.
    # 
    def names_of_s *ids
      s_transitions( *ids ).names( true )
    end
    alias n_s names_of_s
  end # Collections
end # class YPetri::Simulationend::PlaceRepresentation

