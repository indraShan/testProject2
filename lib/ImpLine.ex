defmodule Gossip.ImpLineTopology do
  def create_structure(nodes) do
    # should get numNodes, list of nodes and topology
    # For now just the torus network.
    # But from here we can return whatever we want.

    strctr = %{}
    line = {0, strctr}
    line = iterate_list(nodes, nodes, line)
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
    IO.inspect(strctr)

    strctr =
      Enum.reduce(strctr, fn k, v ->
        IO.puts("#{k} -> #{v}")

        v =
          if MapSet.member?(v, node) do
            MapSet.delete(v, node)
          else
            v
          end
      end)

    strctr = Map.delete(strctr, node)

    topology = put_elem(topology, 1, strctr)
    topology
  end

  defp iterate_list([], _list, topology) do
    topology
  end

  defp iterate_list([node | nodes], list, topology) do
    topology =
      if elem(topology, 0) == 0 do
        topology = put_elem(topology, 0, node)
        strctr = elem(topology, 1)
        nbrs = MapSet.new([])
        strctr = Map.put(strctr, node, nbrs)
        put_elem(topology, 1, strctr)
      else
        prev = elem(topology, 0)
        topology = put_elem(topology, 0, node)
        strctr = elem(topology, 1)
        nbrs = Map.get(strctr, prev)

        nbrs = MapSet.put(nbrs, node)

        strctr = Map.put(strctr, prev, nbrs)

        rand_nbr = Enum.random(list)

        new_nbrs = MapSet.new([rand_nbr, prev])
        strctr = Map.put(strctr, node, new_nbrs)

        put_elem(topology, 1, strctr)
      end

    # IO.inspect topology
    topology = iterate_list(nodes, list, topology)
    topology
  end
end
