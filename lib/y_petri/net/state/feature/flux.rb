# encoding: utf-8

class YPetri::Net::State
  class Feature
    # Flux of a Petri net TS transition.
    # 
    class Flux < Feature
      attr_reader :transition

      class << self
        def parametrize *args
          Class.instance_method( :parametrize ).bind( self ).( *args ).tap do |ç|
            ç.instance_variable_set( :@instances,
                                     Hash.new do |hsh, id|
                                       case id
                                       when Firing then
                                         hsh[ id.transition ]
                                       when ç.net.Transition then
                                         hsh[ id ] = ç.__new__( id )
                                       else
                                         hsh[ ç.net.transition( id ) ]
                                       end
                                     end )
          end
        end

        attr_reader :instances

        alias __new__ new

        def new id
          instances[ id ]
        end

        def of transition_id
          new transition_id
        end
      end

      def initialize id
        @transition = net.transition( id.is_a?( Flux ) ? id.transition : id )
      end

      def extract_from arg, **nn
        case arg
        when YPetri::Simulation then
          arg.send( :TS_transitions, [ transition ] ).flux.first
        else
          fail TypeError, "Argument type not supported!"
        end
      end

      def label
        "Φ:#{transition.name}"
      end
    end # class Flux
  end # class Feature
end # YPetri::Net::State
