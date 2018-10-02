defmodule Gossip.Topology do
  @full_network_type "full"
  @grid3d_network_type "3D"
  @rand2d_network_type "rand2D"
  @torus_network_type "torus"
  @line_network_type "line"
  @imp2d_network_type "imp2D"

  def create_topology(type, nodes) do
    case type do
      @full_network_type ->
        Gossip.FullNetworkTopology.create_structure(nodes)

      @grid3d_network_type ->
        Gossip.Grid3DTopology.create_structure(nodes)

      @rand2d_network_type ->
        Gossip.Rand2DTopology.create_structure(nodes)

      @torus_network_type ->
        Gossip.TorusTopology.create_structure(nodes)

      @line_network_type ->
        Gossip.LineTopology.create_structure(nodes)

      @imp2d_network_type ->
        Gossip.ImpLineTopology.create_structure(nodes)

      _ ->
        IO.puts("Unsupported network type!!!")
        Gossip.FullNetworkTopology.create_structure(nodes)
    end
  end

  def neighbour_for_node(type, topology, node) do
    case type do
      @full_network_type ->
        Gossip.FullNetworkTopology.neighbour_for_node(topology, node)

      @grid3d_network_type ->
        Gossip.Grid3DTopology.neighbour_for_node(topology, node)

      @rand2d_network_type ->
        Gossip.Rand2DTopology.neighbour_for_node(topology, node)

      @torus_network_type ->
        Gossip.TorusTopology.neighbour_for_node(topology, node)

      @line_network_type ->
        Gossip.LineTopology.neighbour_for_node(topology, node)

      @imp2d_network_type ->
        Gossip.ImpLineTopology.neighbour_for_node(topology, node)

      _ ->
        IO.puts("Unsupported network type!!!")
        Gossip.FullNetworkTopology.neighbour_for_node(topology, node)
    end
  end

  def remove_node(type, topology, node) do
    case type do
      @full_network_type ->
        Gossip.FullNetworkTopology.remove_node(topology, node)

      @grid3d_network_type ->
        Gossip.Grid3DTopology.remove_node(topology, node)

      @rand2d_network_type ->
        Gossip.Rand2DTopology.remove_node(topology, node)

      @torus_network_type ->
        Gossip.TorusTopology.remove_node(topology, node)

      @line_network_type ->
        Gossip.LineTopology.remove_node(topology, node)

      @imp2d_network_type ->
        Gossip.ImpLineTopology.remove_node(topology, node)

      _ ->
        IO.puts("Unsupported network type!!!")
        Gossip.FullNetworkTopology.remove_node(topology, node)
    end
  end

  def debug_node_count(type, topology) do
    case type do
      @full_network_type ->
        Gossip.FullNetworkTopology.debug_node_count(topology)

      @grid3d_network_type ->
        Gossip.Grid3DTopology.debug_node_count(topology)

      @rand2d_network_type ->
        Gossip.Rand2DTopology.debug_node_count(topology)

      @torus_network_type ->
        Gossip.TorusTopology.debug_node_count(topology)

      @line_network_type ->
        Gossip.LineTopology.debug_node_count(topology)

      @imp2d_network_type ->
        Gossip.ImpLineTopology.debug_node_count(topology)

      _ ->
        IO.puts("Unsupported network type!!!")
        Gossip.FullNetworkTopology.debug_node_count(topology)
    end
  end
end
