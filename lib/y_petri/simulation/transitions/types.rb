# encoding: utf-8

require_relative 'a'
require_relative 'A'
require_relative 't'
require_relative 'T'
require_relative 's'
require_relative 'S'
require_relative 'ts'
require_relative 'Ts'
require_relative 'tS'
require_relative 'TS'

# A mixin with transition type selectors.
# 
class YPetri::Simulation::Transitions
  module Types
    # Subset of s type transitions, if any.
    # 
    def s
      ( @Type_s ||= Class.new( self.class ).tap do |klass|
          klass.class_exec { include Type_s }
        end ).load subset( &:s? )
    end

    # Subset of S type transitions, if any.
    # 
    def S
      ( @Type_S ||= Class.new( self.class ).tap do |klass|
          klass.class_exec { include Type_S }
        end ).load subset( &:S? )
    end

    # Subset of t type transitions, if any.
    # 
    def t
      ( @Type_t ||= Class.new( self.class ).tap do |klass|
          klass.class_exec { include Type_t }
        end ).load subset( &:t? )
    end

    # Subset of T type transitions, if any.
    # 
    def T
      ( @Type_T ||= Class.new( self.class ).tap do |klass|
          klass.class_exec { include Type_T }
        end ).load subset( &:T? )
    end

    # Subset of ts type transitions, if any.
    # 
    def ts
      ( @Type_ts ||= Class.new( self.class ).tap do |klass|
          klass.class_exec { include Type_ts }
        end ).load subset( &:ts? )
    end

    # Subset of tS type transitions, if any.
    # 
    def tS
      ( @Type_tS ||= Class.new( self.class ).tap do |klass|
          klass.class_exec { include Type_tS }
        end ).load subset( &:tS? )
    end

    # Subset of Ts type transitions, if any.
    # 
    def Ts
      ( @Type_Ts ||= Class.new( self.class ).tap do |klass|
          klass.class_exec { include Type_Ts }
        end ).load subset( &:Ts? )
    end

    # Subset of TS type transitions, if any.
    # 
    def TS
      ( @Type_TS ||= Class.new( self.class ).tap do |klass|
          klass.class_exec { include Type_TS }
        end ).load subset( &:TS? )
    end

    # Subset of A type transitions, if any.
    # 
    def A
      ( @Type_A ||= Class.new( self.class ).tap do |klass|
          klass.class_exec { include Type_A }
        end ).load subset( &:A? )
    end

    # Subset of a type transitions, if any.
    # 
    def a
      ( @Type_a ||= Class.new( self.class ).tap do |klass|
          klass.class_exec { include Type_a }
        end ).load subset( &:a? )
    end
  end # Types
end # class YPetri::Simulation::Transitions
