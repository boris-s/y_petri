#encoding: utf-8

# Representation of a YPetri::Place inside a YPetri::Simulation instance.
#
class YPetri::Simulation::NodeRepresentation
  ★ NameMagic
  ★ YPetri::Simulation::Dependency

  attr_reader :source # source place

  delegate :simulation, to: "self.class"

  # Expect a single YPetri place as an argument.
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
