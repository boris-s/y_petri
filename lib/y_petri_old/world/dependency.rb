# encoding: utf-8

# Provides basic skeleton for dependency injection for the triples of the
# parametrized subclasses of Place, Transition and Net in different workspaces.
# 
class YPetri::World
  module Dependency
    delegate :Place, :Transition, :Net, to: :world

    # Place instance identification.
    # 
    def place id
      world.place( id )
    end

    # Transition instance identification.
    # 
    def transition id
      world.transition( id )
    end

    # Node instance identification.
    # 
    def node id
      begin
        place( id )
      rescue NameError, TypeError
        begin
          transition( id )
        rescue NameError, TypeError => err
          raise TypeError, "Unrecognized node: #{id} (#{err})"
        end
      end
    end

    # Net instance identification.
    # 
    def net id
      Net().instance( id )
    end
  end # module Dependency
end # module YPetri::World
