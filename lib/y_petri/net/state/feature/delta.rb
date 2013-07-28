# encoding: utf-8

class YPetri::Net::State
  class Feature
    # Change of a Petri net place caused by a certain set of transitions.
    # 
    class Delta < Feature
      attr_reader :place, :transitions, :step

      class << self
        def parametrize *args
          Class.instance_method( :parametrize ).bind( self ).( *args ).tap do |ç|
            Hash.new do |hsh, id|
              if id.is_a? Delta then
                hsh[ [ id.place,
                       transitions: id.transitions.sort( &:object_id ) ] ]
              else
                p, tt = id.fetch( 0 ), id.fetch( 1 ).fetch( :transitions )
                step = id[:step]
                if p.is_a? ç.net.Place and tt.all? { |t| t.is_a? ç.net.Transition }
                  if tt = tt.sort then
                    hsh[ id ] = ç.__new__( *id )
                  else
                    hsh[ [ p, transitions: tt.sort ] ]
                  end
                else
                  hsh[ [ ç.net.place( p ), transitions: ç.net.transitions( tt ) ] ]
                end
              end
            end.tap { |ꜧ| ç.instance_variable_set :@instances, ꜧ }
          end
        end

        def of place_id, transitions: []
          new place_id, transitions
        end
      end

      def initialize *id
        @place = net.place id.fetch( 0 )
        @transitions = net.transitions id.fetch( 1 ).fetch( :transitions )
      end

      def extract_from arg, **nn
        # **nn is here because of timed / timeless possibility, where
        # **nn would contain :step named argument.
        case arg
        when YPetri::Simulation then
          _T = arg.send( :T_transitions, transitions )
          _t = arg.send( :t_transitions, transitions )
          if _T.empty? then _t.delta.fetch( place ) else # time step is required
            _t.delta.fetch( place ) + _T.delta( nn[:step] ).fetch( place )
          end
        else
          fail TypeError, "Argument type not supported!"
        end
      end

      def to_s
        place.name
      end
    end # class Delta
  end # class Feature
end # YPetri::Net::State
