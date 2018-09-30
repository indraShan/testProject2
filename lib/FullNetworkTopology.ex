defmodule Gossip.FullNetworkTopology do
  def create_structure(nodes) do
    # For now just the full network.
    # But from here we can return whatever we want.
    %{nodes: nodes}
  end

  # This method gets called with the exact parameter that was returned from the
  # create_structure method
  def neighbour_for_node(topology, node) do
    list = Map.get(topology, :nodes)
    random = Enum.random(0..(length(list) - 1))
    neighbour = Enum.at(list, random)

    neighbour =
      if neighbour == node do
        neighbour_for_node(topology, node)
      else
        neighbour
      end

    neighbour
  end

  def debug_node_count(topology) do
    list = Map.get(topology, :nodes)
    length(list)
  end

  def remove_node(topology, node) do
    list = Map.get(topology, :nodes)
    %{nodes: List.delete(list, node)}
  end
end
