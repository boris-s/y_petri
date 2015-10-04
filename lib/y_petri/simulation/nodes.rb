# encoding: utf-8

class YPetri::Simulation
  # An array of simulation-owned places and/or transitions.
  # 
  class Nodes < Array
    ★ Dependency
    
    class << self
      # New collection constructor
      # 
      def load collection
        new.tap { |inst| inst.load collection }
      end
    end
    
    delegate :simulation, to: "self.class"
    
    # Loads nodes to this collection.
    # 
    def load nodes
      nodes.each{ |node| push node }
    end
    
    # Creates a subset of this collection (of the same class).
    # 
    def subset nodes=nil, &block # TODO: Rename to subarray
      if block_given? then
        fail ArgumentError, "If block given, arguments not allowed!" unless
          nodes.nil?
        self.class.load select( &block )
      else
        fail ArgumentError, "A collection or a block expected!" if nodes.nil?
        nn = Nodes( nodes )
        nn.all? { |node| include? node } or
          fail TypeError, "All subset elements must be in the collection."
        self.class.load( nn )
      end
    end
    
    # Returns an array of the node sources (nodes in the underlying net).
    # 
    def sources
      map &:source
    end
    alias to_sources sources
  end
end
