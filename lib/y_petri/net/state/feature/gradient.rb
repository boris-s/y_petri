# encoding: utf-8

class YPetri::Net::State
  class Feature
    # Gradient of a Petri net place caused by a certain set of T transitions.
    # 
    class Gradient < Feature
      attr_reader :place, :transitions

      class << self
        def parametrize *args
          Class.instance_method( :parametrize ).bind( self ).( *args ).tap do |ç|
            Hash.new do |hsh, id|
              if id.is_a? Gradient then
                hsh[ [ id.place, transitions: id.transitions.sort( &:object_id ) ] ]
              else
                p, tt = id.fetch( 0 ), id.fetch( 1 ).fetch( :transitions )
                if p.is_a? net.Place and tt.all? { |t| t.is_a? net.Transition }
                  if tt == tt.sort then
                    hsh[ id ] = ç.__new__( *id )
                  else
                    hsh[ [ p, transitions: tt.sort ] ]
                  end
                else
                  hsh[ [ net.place( p ), transitions: net.transitions( tt ) ] ]
                end
              end
            end.tap { |ꜧ| ç.instance_variable_set :@instances, ꜧ }
          end
        end

        attr_reader :instances

        alias __new__ new

        def new *id
          instances[ id ]
        end

        def of *id
          new *id
        end
      end

      def initialize *id
        @place = net.place id.fetch( 0 )
        @transitions = net.transitions id.fetch( 1 ).fetch( :transitions )
      end

      def extract_from arg, **nn
        case arg
        when YPetri::Simulation then
          arg.send( :T_transitions, transitions ).gradient.fetch( place )
        else
          fail TypeError, "Argument type not supported!"
        end
      end

      def to_s
        place.name
      end
    end # class Gradient
  end # class Feature
end # YPetri::Net::State
