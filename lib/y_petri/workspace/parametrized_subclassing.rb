
module YPetri::Workspace::ParametrizedSubclassing
  def initialize
    # Parametrized subclasses of Place, Transition and Net.
    @Place = place_subclass = Class.new( YPetri::Place )
    @Transition = transition_subclass = Class.new YPetri::Transition
    @Net = net_subclass = Class.new YPetri::Net

    # Make them namespaces and inject dependencies:
    [ @Place, @Transition, @Net ].each do |klass|
      klass.namespace!
      klass.class_exec do # make'em work together
        define_method :Place do place_subclass end
        define_method :Transition do transition_subclass end
        define_method :Net do net_subclass end
        private :Place, :Transition, :Net # Redeclare private after redef???
      end
    end

    super # param. subclassing achieved, proceed ahead normally
  end # def initialize
end # module YPetri::Workspace::ParametrizedSubclassing
