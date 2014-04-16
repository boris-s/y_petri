# encoding: utf-8

class YPetri::Simulation
  # An array of simulation owned places and/or transitions.
  # 
  class Elements < Array
    ★ Dependency

    class << self
      # New collection constructor
      #
      def load collection
        new.tap { |inst| inst.load collection }
      end
    end

    delegate :simulation, to: "self.class"

    # Loads elements to this collection.
    #
    def load elements
      elements.each{ |e| push e }
    end

    # Creates a subset of this collection (of the same class).
    # 
    def subset elements=nil, &block
      if block_given? then
        fail ArgumentError, "If block given, arguments not allowed!" unless
          elements.nil?
        self.class.load select( &block )
      else
        fail ArgumentError, "A collection or a block expected!" if elements.nil?
        ee = Elements( elements )
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
