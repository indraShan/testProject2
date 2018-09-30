defmodule Gossip.Topology do
  @full_network_type "full"
  @grid3d_network_type "grid3d"
  @rand2d_network_type "rand2d"
  @torus_network_type "torus"

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

      _ ->
        IO.puts("Unsupported network type!!!")
        Gossip.FullNetworkTopology.remove_node(topology, node)
    end
  end
end
