# encoding: utf-8

require 'matrix'

# Patches the Matrix class with methods that generate code for direct vector
# access.
#
class Matrix
  class << self
    # Builds a code string for accessing the vector values at given indices.
    # 
    def column_vector_access_code vector: (fail ArgumentError, "No vector!"),
                                  indices: (fail ArgumentError, "No indices!")
      indices.map { |i| "#{vector}[#{i}, 0]" }.join( ", " )
    end
  
    # Builds a code string for assigning to a vector at given indices.
    # 
    def column_vector_assignment_code vector: (fail ArgumentError, "No vector!"),
                                      indices: (fail ArgumentError, "No indices!"),
                                      source: (fail ArgumentError, "No source!")
      code_lines = indices.map.with_index do |i, source_pos|
        "#{vector}.send( :[]=, #{i}, 0, #{source}.fetch( #{source_pos} ) )" if i
      end
      code_lines.compact.join( "\n" ) << "\n"
    end

    # Builds a code string for incrementing a vector at given indices. Source is
    # a vector.
    # 
    def column_vector_increment_code vector: (fail ArgumentError, "No vector!"),
                                     indices: (fail ArgumentError, "No indices!"),
                                     source: (fail ArgumentError, "No source!")
      code_lines = indices.map.with_index do |i, source_pos|
        "#{vector}.send( :[]=, #{i}, 0, %s )" %
          "#{vector}[#{i}, 0] + #{source}[#{source_pos}, 0]" if i
      end
      code_lines.compact.join( "\n" ) << "\n"
    end

    # Builds a code string for incrementing a vector at given indices. Source is
    # an array.
    # 
    def column_vector_increment_by_array_code vector: (fail ArgumentError, "No vector!"),
                                              indices: (fail ArgumentError, "No indices!"),
                                              source: (fail ArgumentError, "No source!")
      code_lines = indices.map.with_index do |i, source_pos|
        "#{vector}.send( :[]=, #{i}, 0, %s )" %
          "#{vector}[#{i}, 0] + #{source}[#{source_pos}]" if i
      end
      code_lines.compact.join( "\n" ) << "\n"
    end
  end

  # Builds a closure for incrementing a column at given indices.
  # 
  def increment_at_indices_closure indices: (fail ArgumentError, "No indices!")
    v = self
    eval "-> delta do\n%s\nend" %
      self.class.column_vector_increment_code( vector: "v",
                                               indices: indices,
                                               source: "delta" )
  end
end
