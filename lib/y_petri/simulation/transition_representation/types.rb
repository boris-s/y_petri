#encoding: utf-8

# A mixin with transition types.
# 
class YPetri::Simulation
  class TransitionRepresentation
    include NameMagic
    include DependencyInjection

    module Types
      attr_reader :type

      def initialize *args
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
  end # class TransitionRepresentation
end # class YPetri::Simulation
