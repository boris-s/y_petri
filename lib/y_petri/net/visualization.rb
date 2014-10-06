# encoding: utf-8

# Own visualization capabilities of a Petri net.
# 
module YPetri::Net::Visualization
  # Visualizes the net with Graphviz.
  # 
  def visualize
    require 'graphviz'
    γ = GraphViz.new :G
    # Add places and transitions.
    place_nodes = places.map.with_object Hash.new do |pl, ꜧ|
      ꜧ[pl] = γ.add_nodes pl.name.to_s,
                          fillcolor: 'lightgrey',
                          color: 'grey',
                          style: 'filled'
    end
    transition_nodes = transitions.map.with_object Hash.new do |tr, ꜧ|
      ꜧ[tr] = γ.add_nodes tr.name.to_s,
                          shape: 'box',
                          fillcolor: ( if tr.assignment? then 'yellow'
                                       elsif tr.type == :TS then 'lightcyan'
                                       else 'ghostwhite' end ),
                          color: ( if tr.assignment? then 'goldenrod'
                                   elsif tr.type == :TS then 'cyan'
                                   else 'grey' end ),
                          style: 'filled'
    end
    # Add Petri net arcs.
    transition_nodes.each { |tr, tr_node|
      if tr.assignment? then
        tr.codomain.each { |pl|
          γ.add_edges tr_node, place_nodes[pl], color: 'goldenrod'
        }
        ( tr.domain - tr.codomain ).each { |pl|
          γ.add_edges tr_node, place_nodes[pl], color: 'grey', arrowhead: 'none'
        }
      elsif tr.type == :TS then
        tr.codomain.each { |pl|
          if tr.stoichio[pl] > 0 then # producing arc
            γ.add_edges tr_node, place_nodes[pl], color: 'cyan'
          elsif tr.stoichio[pl] < 0 then # consuming arc
            γ.add_edges place_nodes[ pl ], tr_node, color: 'cyan'
          else # zero stoichiometry => test arc
            γ.add_edges place_nodes[ pl ], tr_node, color: 'grey', arrowhead: 'none'
          end
        }
        ( tr.domain - tr.codomain ).each { |pl| # remaining test arcs
          γ.add_edges tr_node, place_nodes[pl], color: 'grey', arrowhead: 'none'
        }
      elsif tr.S?
        tr.codomain.each { |pl|
          if tr.stoichio[pl] > 0 then # producing arc
            γ.add_edges tr_node, place_nodes[pl], color: 'cyan'
          elsif tr.stoichio[pl] < 0 then # consuming arc
            γ.add_edges place_nodes[ pl ], tr_node, color: 'cyan'
          else # zero stoichiometry => test arc
            γ.add_edges place_nodes[ pl ], tr_node, color: 'grey', arrowhead: 'none'
          end
        }
        ( tr.domain - tr.codomain ).each { |pl| # remaining test arcs
          γ.add_edges tr_node, place_nodes[pl], color: 'grey', arrowhead: 'none'
        }
      else
        tr.codomain.each { |pl|
          γ.add_edges tr_node, place_nodes[pl], color: 'cyan'
        }
        ( tr.domain - tr.codomain ).each { |pl|
          γ.add_edges tr_node, place_nodes[pl], color: 'grey', arrowhead: 'none'
        }
      end
    }
    # Generate output image.
    puts File.expand_path "~/y_petri_graph.png"
    γ.output png: File.expand_path( "~/y_petri_graph.png" )
    # require 'y_support/kde'
    YSupport::KDE.show_file_with_kioclient File.expand_path( "~/y_petri_graph.png" )
  end

  private

  # Display a file with kioclient (KDE).
  # 
  def show_file_with_kioclient( file_name )
    system "sleep 0.2; kioclient exec 'file:%s'" %
      File.expand_path( '.', file_name )
  end
end # module YPetri::Net::Visualization
