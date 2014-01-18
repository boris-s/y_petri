# encoding: utf-8

# Connectivity aspect of a transition.
#
module YPetri::Transition::Arcs
  # Names of upstream places.
  # 
  def domain_pp; domain.map { |p| p.name || p.object_id } end
  alias :upstream_pp :domain_pp

  # Names of downstream places.
  # 
  def codomain_pp; codomain.map { |p| p.name || p.object_id } end
  alias :downstream_pp :codomain_pp

  # Union of action arcs and test arcs.
  # 
  def arcs
    domain | codomain
  end

  # Names of the (places connected to) the transition's arcs.
  # 
  def aa
    # For anonymous arcs, true causes instances themselves to be returned.
    arcs.names true
  end

  # Marking of the domain places.
  # 
  def domain_marking; domain.map &:marking end

  # Marking of the codomain places.
  # 
  def codomain_marking; codomain.map &:marking end

  # Recursive firing of the upstream net portion (honors #cocked?).
  # 
  def fire_upstream_recursively
    return false unless cocked?
    uncock
    upstream_places.each &:fire_upstream_recursively
    fire!
    return true
  end

  # Recursive firing of the downstream net portion (honors #cocked?).
  # 
  def fire_downstream_recursively
    return false unless cocked?
    uncock
    fire!
    downstream_places.each &:fire_downstream_recursively
    return true
  end
end # module YPetri::Transition::Arcs
