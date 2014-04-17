# encoding: utf-8

# Overrride of World::Dependency to enable Transition instances not belonging
# to any World instance.
# 
module YPetri::Transition::UsableWithoutWorld
  def place id
    super rescue Place().instance( id )
  end

  def transition id
    super rescue Transition().instance( id )
  end
end # class YPetri::Transition::UsableWithoutWorld
