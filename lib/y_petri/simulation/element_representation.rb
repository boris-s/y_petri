#encoding: utf-8

# Representation of a YPetri::Place inside a YPetri::Simulation instance.
#
class YPetri::Simulation
  class ElementRepresentation
    include NameMagic
    include DependencyInjection

    attr_reader :source # source place

    # Expect a single YPetri place as an argument.
    # 
    def initialize net_element_id
      @source = net.element( net_element_id )
    end
  end # class ElementRepresentation
end # class YPetri::Simulation