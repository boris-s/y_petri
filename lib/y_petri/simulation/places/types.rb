# encoding: utf-8

require_relative 'free'
require_relative 'clamped'

# A mixin with place type selectors.
# 
class YPetri::Simulation::Places
  module Types
    # Subset of free places, if any.
    # 
    def free
      ( @Type_free ||= Class.new self.class do
          include Type_free
        end ).load subset( &:free? )
    end

    # Subset of clamped places, if any.
    # 
    def clamped
      ( @Type_clamped ||= Class.new self.class do
          include Type_clamped
        end ).load subset( &:clamped? )
    end
  end # Types
end # class YPetri::Simulation::Places
