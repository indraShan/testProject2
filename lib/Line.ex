defmodule Gossip.LineTopology do
  def create_structure(nodes) do
    # should get numNodes, list of nodes and topology
    # For now just the torus network.
    # But from here we can return whatever we want.

    strctr = %{}
    line = {0, strctr}
    line = iterate_list(nodes, line)
    # IO.inspect line
    # IO.puts "Done creating topology"
    line
  end

  # This method gets called with the exact parameter that was returned from the
  # create_structure method
  def neighbour_for_node(topology, node) do
    strctr = elem(topology, 1)
    nbrs = Map.get(strctr, node)

    neighbour =
      if length(nbrs) > 0 do
        Enum.random(nbrs)
      else
        nil
      end

    neighbour =
      if neighbour == node do
        neighbour_for_node(topology, node)
      else
        neighbour
      end

    neighbour
  end

  def remove_node(topology, node) do
    strctr = elem(topology, 1)
    nbrs = Map.get(strctr, node)
    # IO.inspect(nodes)

    strctr = del_elem(nbrs, strctr, node)

    strctr = Map.delete(strctr, node)
    topology = put_elem(topology, 1, strctr)
    topology
  end

  defp del_elem([], strctr, _x) do
    strctr
  end

  defp del_elem([nbr | nbrs], strctr, node) do
    strctr =
      if nbr != 0 do
        new_nbrs = Map.get(strctr, nbr)
        new_nbrs = new_nbrs -- [node]
        strctr = Map.put(strctr, nbr, new_nbrs)
        del_elem(nbrs, strctr, node)
      else
        strctr
      end

    strctr
  end

  defp iterate_list([], topology) do
    topology
  end

  defp iterate_list([node | nodes], topology) do
    topology =
      if elem(topology, 0) == 0 do
        topology = put_elem(topology, 0, node)
        strctr = elem(topology, 1)
        nbrs = []
        strctr = Map.put(strctr, node, nbrs)
        put_elem(topology, 1, strctr)
      else
        prev = elem(topology, 0)
        topology = put_elem(topology, 0, node)
        strctr = elem(topology, 1)
        nbrs = Map.get(strctr, prev)
        # nbrs = List.delete_at(nbrs, 0)
        nbrs = [node] ++ nbrs
        strctr = Map.put(strctr, prev, nbrs)
        strctr = Map.put(strctr, node, [prev])
        put_elem(topology, 1, strctr)
      end

    # IO.inspect topology
    topology = iterate_list(nodes, topology)
    topology
  end
end
