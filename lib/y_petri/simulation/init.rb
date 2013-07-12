#encoding: utf-8

# Initialization methods.
# 
class YPetri::Simulation

  private

  # This method constructs a mental image of the supplied net's places, marking
  # clamp prescriptions, and initial marking prescriptions.
  # 
  def init_places( marking_clamps, initial_marking, use_default_marking: true )
    # Seting up the place and transition collections.
    @places = Places().load( net.places )
    @marking_clamps = MarkingClamps().load( marking_clamps )
    @initial_marking = InitialMarking().load( initial_marking )
    @places.complete_initial_marking( use_default_marking: use_default_marking )
    @f2a = free_places.correspondence_matrix( places )
    @c2a = clamped_places.correspondence_matrix( places )
  end

  # This method constructs a mental image of the supplied net's transitions.
  # 
  def init_transitions
    @transitions = Transitions().load( net.transitions )
    @tS_stoichiometry_matrix = transitions.tS.stoichiometry_matrix
    @TS_stoichiometry_matrix = transitions.TS.stoichiometry_matrix
    @tS_SM = transitions.tS.SM
    @TS_SM = transitions.TS.SM
  end

  # Initialization subroutine that creates parametrized element subclasses
  # representing simulated Petri net elements and their collections.
  # 
  def init_parametrized_subclasses
    @Place = Class.new( PlaceRepresentation ).tap &:namespace!
    @Transition = Class.new( TransitionRepresentation ).tap &:namespace!
    @Places = Class.new( Places )
    @Transitions = Class.new( Transitions )
    @PlaceMapping = Class.new( PlaceMapping )
    @MarkingClamps = Class.new( MarkingClamps )
    @InitialMarking = Class.new( InitialMarking )
    @MarkingVector = Class.new( MarkingVector )
    tap do |sim| # Dependency injection.
      [ Place(),
        Transition(),
        Places(),
        Transitions(),
        PlaceMapping(),
        MarkingClamps(),
        InitialMarking(),
        MarkingVector(),
        MarkingVector().singleton_class
      ].each { |ç| ç.class_exec { define_method :simulation do sim end } }
    end
  end
end # class YPetri::Simulation
