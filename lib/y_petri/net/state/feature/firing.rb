# encoding: utf-8
class YPetri::Net::State
  class Feature
    # Firing of a Petri net tS transition.
    # 
    class Firing < Feature
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

        def of id
          new id
        end
      end

      def initialize transition
        @transition = net.transition( transition )
      end

      def extract_from arg, **nn
        case arg
        when YPetri::Simulation then
          arg.send( :tS_transitions, [ transition ] ).firing.first
        else
          fail TypeError, "Argument type not supported!"
        end
      end

      def label
        "f:#{transition.name}"
      end
    end # class Firing
  end # class Feature
end # YPetri::Net::State
