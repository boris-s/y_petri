#encoding: utf-8

# Provides basic skeleton for dependency injection for the triples of the
# parametrized subclasses of Place, Transition and Net in different workspaces.
#
module YPetri::DependencyInjection

  private

  # Place class -- to be overriden in subclasses for dependency injection.
  # 
  def Place
    YPetri::Place
  end

  # Transition class -- to be overriden in subclasses for dependency injection.
  # 
  def Transition
    YPetri::Transition
  end

  # Net class -- to be overriden in subclasses for dependency injection
  # 
  def Net
    YPetri::Net
  end

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

  # Net instance identification.
  # 
  def net id
    Net().instance( id )
  end
end # module YPetri::DependencyInjection
