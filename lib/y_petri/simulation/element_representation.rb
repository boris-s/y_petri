#encoding: utf-8

# Representation of a YPetri::Place inside a YPetri::Simulation instance.
#
class YPetri::Simulation::ElementRepresentation
  ★ NameMagic
  ★ YPetri::Simulation::Dependency

  attr_reader :source # source place

  delegate :simulation, to: "self.class"

  # Expect a single YPetri place as an argument.
  # 
  def initialize net_element_id
    @source = net.element( net_element_id )
  end

  # Tweak the #to_s method to give the element representations the inspect
  # string of type #<Name>.
  # 
  def to_s
    "#<#{super}>"
  end
end # class YPetri::Simulation::ElementRepresentation
