# encoding: utf-8

# A mixin with place type selectors.
# 
class YPetri::Simulation::Places
  module Types
    # Subset of free places, if any.
    # 
    def free
      ( @Type_free ||= Class.new( self.class ).tap do |klass|
          klass.class_exec { include Type_free }
        end ).load subset( &:free? )
    end
    
    # Subset of clamped places, if any.
    # 
    def clamped
      ( @Type_clamped ||= Class.new( self.class ).tap do |klass|
          klass.class_exec { include Type_clamped }
        end ).load subset( &:clamped? )
    end
  end # Types
end # class YPetri::Simulation::Places
