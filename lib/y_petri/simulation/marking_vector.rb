# encoding: utf-8

class YPetri::Simulation
  # The class in which places' marking is stored inside a simulation.
  #
  class MarkingVector < Matrix
    ★ Dependency

    class << self
      include Dependency

      attr_reader :annotation

      # Constructs a marking vector from a hash places >> values, or from
      # an array, in which case, it is assumed that the marking vector
      # corresponds to all the places in the simulation.
      #
      # TODO: I don't like having to write MarkingVector[ [ 1, 2, 3 ] ] instead
      # of MarkingVector[ 1, 2, 3 ], but I accepted and endorsed it long time
      # ago as a necessary tax for being able to distinguish between the user
      # meaning to supply no arguments and the user meaning to supply empty
      # vector.
      # 
      def [] arg
        case arg
        when Hash then annotated_with( arg.keys )[ arg.values ]
        when Array then
          if annotation then
            fail ArgumentError, "The size of the argument (#{arg.size}) does " +
              "not match the annotation size (#{annotation.size})!" unless
              msg unless arg.size == annotation.size
            column_vector( arg )
          else
            annotated_with( places )[ arg ]
          end
        else
          self[ arg.each.to_a ]
        end
      end

      # Returns a subclass of self annotated with the supplied array of places.
      # 
      def annotated_with places
        annot = annotation ? annotation.subset( places ) : Places( places )
        Class.new self do @annotation = annot end
      end

      # Without arguments, constructs the starting marking vector for all the
      # places, using either initial values, or clamp values. Optionally, an
      # array of places or place ids can be supplied, for which the starting
      # vector is returned.
      # 
      def starting places=nil
        if places.nil? then
          return starting( places() ) if annotation.nil?
          self[ annotation.map { |p| p.free? ? p.initial_marking : p.clamp } ]
        else
          annotated_with( places ).starting
        end
      end

      # Without arguments, constructs a zero marking vector for all the places.
      # Optionally, an array of places or places ids can be supplied, for which
      # the zero vector is returned.
      # 
      def zero places=nil
        starting( places ) * 0
      end
    end

    delegate :simulation, to: "self.class"

    # Expects an array of places or place ids, and creates a subset of this
    # marking vector. Alternatively, a block can be supplied that performs
    # the places selection similarly to +Enumerable#select+.
    # 
    def select places, &block
      if block_given? then
        fail ArgumentError, "Arguments not allowed if block given!" unless
          place_ids.empty?
        select annotation.select &block
      else
        pp = places( *places )
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
      case arg
      when Hash then
        # Hash is first converted into a PlaceMapping instance (mp).
        mp = simulation.PlaceMapping().load( arg )
        # Updated marking vector is constructed using reliable methods
        # self.class.starting and self#set.
        updated = mp.each_with_object self.class.starting do |(place, value), mv|
          mv.set place, value
        end
        # Updated marking vector is then converted into an array and #reset! method
        # is called upon it again to actually perform in-place update of this vector.
        # TODO: The above is slightly inefficient -- constructing a new vector when
        # in-place modification seems a better solution. But if it works, it's a
        # strong reason to not fix it until we are in the optimization stage.
        reset! updated.column_to_a
      else # array arg assumed
        arg.each.to_a.zip( annotation ).map { |value, place| set place, value }
      end
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

    # Pretty-prints the marking vector.
    # 
    def pretty_print *args
      to_h.pretty_print_numeric_values *args
    end
    alias pp pretty_print
  end
end
