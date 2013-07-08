# Basic elements of a simulation, a mixin intended for YPetri::Simulation.
#
class YPetri::Simulation
  class Elements < Array
    include DependencyInjection

    class << self
      # New collection constructor
      # 
      def load collection
        new.tap { |inst| inst.load collection }
      end
    end

    # Loads elements to this collection.
    # 
    def load elements
      elements.each{ |e| push e }
    end

    # Creates a subset of this collection (of the same class).
    # 
    def subset *elements, &block
      if block_given? then
        msg = "If block is given, arguments are not allowed!"
        fail ArgumentError, msg unless elements.empty?
        self.class.load select( &block )
      else
        ee = elements( *elements ).aT_all "element" do |e| include? e end
        self.class.load( ee )
      end
    end
  end
end
