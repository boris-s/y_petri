#encoding: utf-8

# Provides basic skeleton for dependency injection for the triples of the
# parametrized subclasses of Place, Transition and Net in different workspaces.
#
module YPetri::World::Dependency
  delegate :Place, :Transition, :Net, to: :world

  # Place instance identification.
  # 
  def place id
    Place().instance( id )
  end

  # Transition instance identification.
  # 
  def transition id
    Transition().instance( id )
  end

  # Element instance identification.
  # 
  def element id
    begin
      place( id )
    rescue NameError, TypeError
      begin
        transition( id )
      rescue NameError, TypeError => err
        raise TypeError, "Unrecognized place or transition: #{element} (#{err})"
      end
    end
  end

  # Net instance identification.
  # 
  def net id
    Net().instance( id )
  end
end # module YPetri::DependencyInjection
