# encoding: utf-8

# Representation of a +YPetri+ node inside a +YPetri::Simulation+ instance.
# An instance of +YPetri::Simulation+ does is constructed based on an instance
# of +YPetri::Net+, but not directly work with Petri net nodes (that is, it
# does not work with instances of +YPetri::Place+ or +YPetri::Transition+).
# Instead, it creates its own internal representations of the nodes of the
# Petri net it is constructed from -- instances of NodeRepresentation.
#
class YPetri::Simulation::NodeRepresentation
  ★ NameMagic
  ★ YPetri::Simulation::Dependency

  attr_reader :source # source place

  delegate :simulation, to: "self.class"

  # Expect a single YPetri node (place or transition) as an argument.
  # 
  def initialize net_node_id
    @source = net.node( net_node_id )
  end

  # Tweak the #to_s method to give the node representations the inspect string
  # of type #<Name>.
  # 
  def to_s
    "#<#{super}>"
  end
end # class YPetri::Simulation::NodeRepresentation
