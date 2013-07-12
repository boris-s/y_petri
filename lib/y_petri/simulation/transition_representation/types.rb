#encoding: utf-8

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

# A mixin with transition types.
# 
class YPetri::Simulation::TransitionRepresentation
  module Types
    attr_reader :type

    def type_init *args
      extend case source.type
             when :A then Type_A
             when :TS then Type_TS
             when :Ts then Type_Ts
             when :tS then Type_tS
             when :ts then Type_ts
             else fail TypeError, "Unknown tr. type #{source.type}!" end
      init
    end
    
    # The transition's type.
    # 
    def type
      return :A if A?
      if T? then S? ? :TS : :Ts else S? ? :tS : :ts end
    end
    
    # Is this a TS transition?
    # 
    def TS?
      type == :TS
    end
    
    # Is this a Ts transition?
    # 
    def Ts?
      type == :Ts
    end
    
    # Is this a tS transition?
    # 
    def tS?
      type == :tS
    end
    
    # Is this a ts transition?
    # 
    def ts?
      type == :ts
    end
  end # module Types
end # class YPetri::Simulation::TransitionRepresentation
