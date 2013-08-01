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
            # First, prepare the hash of instances.
            hsh = Hash.new do |ꜧ, id|
              puts "Delta received:"
              p id
              puts "of class #{id.class}, with ancestors:"
              p id.class.ancestors
              if id.is_a? Delta then
                ꜧ[ [ id.place, transitions: id.transitions.sort( &:object_id ) ] ]
              else
                puts "here"
                p id
                puts "id size is #{id.size}"
                p = id.fetch( 0 )
                tt = id
                  .fetch( 1 )
                  .fetch( :transitions )
                if p.is_a? ç.net.Place and tt.all? { |t| t.is_a? ç.net.Transition }
                  if tt == tt.sort then
                    ꜧ[ id ] = ç.__new__( *id )
                  else
                    ꜧ[ [ p, transitions: tt.sort ] ]
                  end
                else
                  ꜧ[ [ ç.net.place( p ), transitions: ç.net.transitions( tt ) ] ]
                end
              end
            end
            # And then, assign it to the :@instances variable.
            ç.instance_variable_set :@instances, hsh
          end
        end

        attr_reader :instances

        alias __new__ new

        def new *args
          return instances[ *args ] if args.size == 1
          instances[ args ]
        end

        def of *args
          new *args
        end
      end

      def initialize place, transitions: net.tt
        @place = net.place( place )
        @transitions = net.transitions( transitions )
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

      def label
        "∂:#{place.name}:#{transitions.size}tt"
      end
    end # class Delta
  end # class Feature
end # YPetri::Net::State
