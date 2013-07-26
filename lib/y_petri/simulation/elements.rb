# Basic elements of a simulation, a mixin intended for YPetri::Simulation.
#
class YPetri::Simulation
  class Elements < Array
    include Dependency
    
    class << self
      # New collection constructor
      #
      def load collection
        new.tap { |inst| inst.load collection }
      end
    end

    delegate :simulation, to: :class
    
    # Loads elements to this collection.
    #
    def load elements
      elements.each{ |e| push e }
    end
    
    # Creates a subset of this collection (of the same class).
    #
    def subset element_ids=nil, &block
      if block_given? then
        msg = "If block is given, arguments are not allowed!"
        fail ArgumentError, msg unless element_ids.nil?
        self.class.load select( &block )
      else
        ee = elements( element_ids )
        ee.all? { |e| include? e } or
          fail TypeError, "All subset elements must be in the collection."
        self.class.load( ee )
      end
    end

    # Returns an array of the element sources (elemens in the original net).
    # 
    def sources
      map &:source
    end
    alias to_sources sources
  end
end
