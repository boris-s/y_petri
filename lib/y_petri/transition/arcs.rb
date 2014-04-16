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

  # Names of the places connected to the transition. The optional argument
  # controls what is returned for unnamed instances, and works just like in
  # <tt>Array#names</tt> method from <tt>y_support/name_magic</tt>:
  # The default value (_nil_) returns _nil_, _true_ returns the instance itself,
  # and _false_ drops the unnamed instances from the list altogether.
  # 
  def aa arg=nil
    arcs.names arg
  end

  # Arc (a place connected to this transition) identifier.
  # 
  def arc id
    place = place( id )
    arcs.find { |p| p == place } or
      fail TypeError, "No place #{id} connected to #{self}!"
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
