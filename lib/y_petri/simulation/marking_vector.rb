# encoding: utf-8

# Basic elements of a simulation, a mixin intended for YPetri::Simulation.
#
class YPetri::Simulation
  class MarkingVector < Matrix
    ★ Dependency

    class << self
      include Dependency

      attr_reader :annotation

      # Constructs a marking vector from a hash places >> values, or from
      # an array, in which case, it is assumed that the marking vector
      # corresponds to all the places in the simulation.
      # 
      def [] arg
        case arg
        when Hash then annotated_with( arg.keys )[ arg.values ]
        when Array then
          if annotation then
            msg = "The size of the argument (#{arg.size}) does not " +
              "correspond to the annotation size (#{annotation.size})!"
            fail ArgumentError, msg unless arg.size == annotation.size
            column_vector arg
          else
            annotated_with( places )[ args ]
          end
        else
          self[ args.each.to_a ]
        end
      end

      # Returns a subclass of self annotated with the supplied places.
      # 
      def annotated_with place_ids
        annot = if annotation then
                  annotation.subset place_ids
                else
                  places( place_ids )
                end
        Class.new self do @annotation = annot end
      end

      # Without arguments, constructs the starting marking vector for all places,
      # using either initial values, or clamp values. Optionally, places can be
      # specified, for which the starting vector is returned.
      # 
      def starting place_ids=nil
        st = -> p { p.free? ? p.initial_marking : p.clamp } # starting value
        if place_ids.nil? then
          return starting places if annotation.nil?
          self[ annotation.map &st ]
        else
          annotated_with( place_ids ).starting
        end
      end

      # Without arguments, constructs a zero marking vector for all places.
      # Optionally, places can be specified, for which the zero vector is
      # returned.
      # 
      def zero( place_ids=nil )
        starting( place_ids ) * 0
      end
    end

    delegate :simulation, to: "self.class"

    # Creates a subset of this marking vector.
    # 
    def select place_ids, &block
      if block_given? then
        msg = "If block is given, arguments are not allowed!"
        fail ArgumentError, msg unless place_ids.empty?
        select annotation.select( &block )
      else
        pp = places( place_ids )
        annotated_subcl = self.class.annotated_with( pp )
        annotated_subcl[ pp.map { |p| fetch p } ]
      end
    end

    # Modifying the vector elements.
    # 
    def set id, value
      self[ index( id ), 0 ] = value
    end

    # Whole vector is reset to a given collection of values. If no argument is
    # given, starting vector is used.
    # 
    def reset! arg=self.class.starting
      arg.each.to_a.zip( annotation ).map { |value, place| set place, value }
    end

    # Access of the vector elements.
    # 
    def fetch id
      self[ index( id ), 0  ]
    end

    # Annotation.
    # 
    def annotation
      self.class.annotation
    end

    # Index of a place.
    # 
    def index id
      if id.is_a? Numeric then
        fail RangeError, "Numeric index must be within 0..#{size}" unless
          ( 0..size ) === id
      else
        annotation.index place( id )
      end
    end

    # Marking vector size -- depends on the annotation.
    # 
    def size
      annotation.size
    end

    # Converts the marking vector (which is a column vector) into an array.
    # 
    def to_a
      ( 0..size - 1 ).map { |i| self[ i, 0 ] }
    end

    # Converts the marking vector into a hash annotation >> values.
    # 
    def to_hash
      annotation >> to_a
    end

    # Converts the marking vector into a hash annotation_names >> values.
    # 
    def to_h
      annotation.names( true ) >> to_a
    end

    # Converts the marking vector into a hash source places >> values.
    # 
    def to_hash_with_source_places
      annotation.sources >> to_a
    end

    # Builds the assignment closure.
    # 
    def increment_closure
      indices_of_free_places = annotation.free.map { |p| annotation.index p }
      increment_at_indices_closure( indices: indices_of_free_places )
    end
  end
end
