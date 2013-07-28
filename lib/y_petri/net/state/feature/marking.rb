# encoding: utf-8

class YPetri::Net::State
  class Feature
    # Marking of a Petri net place.
    # 
    class Marking < Feature
      attr_reader :place

      class << self
        def parametrize *args
          Class.instance_method( :parametrize ).bind( self ).( *args ).tap do |ç|
            Hash.new do |hsh, id|
              case id
              when Marking then hsh[ id.place ]
              when ç.net.Place then hsh[ id ] = ç.__new__( id )
              else hsh[ ç.net.place( id ) ] end
            end.tap { |ꜧ| ç.instance_variable_set :@instances, ꜧ }
          end
        end

        attr_reader :instances

        alias __new__ new

        def new id
          instances[ id ]
        end

        def of id
          new id
        end
      end

      def initialize place
        @place = net.place( place )
      end

      def extract_from arg, **nn
        case arg
        when YPetri::Simulation then
          arg.m( [ place ] ).first
        else
          fail TypeError, "Argument type not supported!"
        end
      end

      def to_s
        place.name
      end
    end # class Marking
  end # class Feature
end # YPetri::Net::State
