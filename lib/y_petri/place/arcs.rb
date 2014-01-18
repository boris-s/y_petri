# encoding: utf-8

# Connectivity aspect of a Petri net place.
# 
module YPetri::Place::Arcs
  # Transitions that can directly add/remove tokens from this place. Aliased as
  # +#upstream_transitions+ and +#ϝ+. (Digamma resembles "f", meaning function,
  # well known from existing spreadsheet software.)
  # 
  attr_reader :upstream_arcs
  alias :upstream_transitions :upstream_arcs
  alias :ϝ :upstream_arcs

  # Transitions whose action directly depends on this place. Aliased as
  # +#downstream_transitions+.
  # 
  attr_reader :downstream_arcs
  alias :downstream_transitions :downstream_arcs

  # All the transitions connected to the place.
  # 
  def arcs
    upstream_arcs | downstream_arcs
  end

  # Names of the (transitions connected to) the place's arcs.
  # 
  def aa
    # For anonymous arcs, true causes instances themselves to be returned.
    arcs.names true
  end

  # Union of the domains of the upstream transitions.
  # 
  def precedents
    upstream_transitions.map( &:upstream_places ).reduce( [], :| )
  end
  alias :upstream_places :precedents

  # Union of the codomains of the downstream transitions.
  # 
  def dependents
    downstream_transitions.map( &:downstream_places ).reduce( [], :| )
  end
  alias :downstream_places :dependents

  # Fires the upstream transitions.
  # 
  def fire_upstream
    upstream_arcs.each &:fire
  end

  # Fires the upstream transitions regardless of cocking. (Normally, transitions
  # should be cocked (+#cock+ method) before they are fired (+#fire+ method).)
  # 
  def fire_upstream!
    upstream_arcs.each &:fire!
  end

  # Fires the whole upstream portion of the net. Cocking ensures that the
  # recursive firing will eventually end.
  # 
  def fire_upstream_recursively
    # LATER: This as a global hash { place => fire_list }
    @upstream_arcs.each &:fire_upstream_recursively
  end

  # Fires the downstream transitions.
  # 
  def fire_downstream
    downstream_arcs.each &:fire
  end

  # Fires the downstream transitions regardless of cocking. (Normally,
  # transitions should be cocked (+#cock+ method) before they are fired (+#fire+
  # method).)
  # 
  def fire_downstream!
    @downstream_arcs.each &:fire!
  end

  # Fires the whole downstream portion of the net. Cocking ensures that the
  # recursive firing will eventually end.
  # 
  def fire_downstream_recursively
    # LATER: This as a global hash { place => fire_list }
    @downstream_arcs.each &:fire_downstream_recursively
  end

  private

  # Notes a new upstream transition.
  # 
  def register_upstream_transition( transition )
    @upstream_arcs << transition
  end

  # Notes a new downstream transition.
  # 
  def register_downstream_transition( transition )
    @downstream_arcs << transition
  end
end # class YPetri::Place::Arcs
