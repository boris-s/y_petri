
module YPetri::Workspace::ParametrizedSubclassing
  def initialize
    # Parametrized subclasses of Place, Transition and Net.
    @Place = place_subclass = Class.new YPetri::Place
    @Transition = transition_subclass = Class.new YPetri::Transition
    @Net = net_subclass = Class.new YPetri::Net

    # Now dependency injection: Let's tell these subclasses to work together.
    [ @Place, @Transition, @Net ].each { |klass|
      klass.class_exec {
        # redefine their Place, Transition, Net method
        define_method :Place do place_subclass end
        define_method :Transition do transition_subclass end
        define_method :Net do net_subclass end
        # I am not sure whether the following line is necessary. Place(),
        # Transition() and Net() methods, which have just been redefined,
        # are originally defined as private in klass. Is it necessary to
        # declare them private explicitly again after redefining?
        private :Place, :Transition, :Net
      }
    }

    super # Parametrized subclassing achieved, proceed ahead normally.
  end # def initialize
end # module YPetri::Workspace::ParametrizedSubclassing
