defmodule Gossip.LineTopology do
  def create_structure(nodes) do
    # should get numNodes, list of nodes and topology
    # For now just the torus network.
    # But from here we can return whatever we want.

    strctr = %{:deleted_set => MapSet.new([])}
    line = {0, strctr}
    line = iterate_list(nodes, line)
    # IO.inspect line
    strctr = elem(line, 1)
    num = map_size(strctr) - 1
    IO.puts("Done creating topology with #{num} nodes")
    strctr
  end

  def debug_node_count(topology) do
    # list = Map.get(topology, :nodes)
    # length(list)
    map_size(topology) - 1
  end

  # This method gets called with the exact parameter that was returned from the
  # create_structure method
  def neighbour_for_node(topology, node) do
    # strctr = elem(topology, 1)
    nbrs = Map.get(topology, node)
    deleted_set = Map.get(topology, :deleted_set)

    {neighbour, topology} =
      if MapSet.size(nbrs) > 0 do
        {Enum.random(nbrs), topology}
      else
        {nil, topology}
      end

    {neighbour, topology} =
      if neighbour != nil && MapSet.member?(deleted_set, neighbour) do
        nbrs = MapSet.delete(nbrs, neighbour)
        topology = Map.put(topology, node, nbrs)
        neighbour_for_node(topology, node)
      else
        {neighbour, topology}
      end

    {neighbour, topology}
  end

  def remove_node(topology, node) do
    # strctr = elem(topology, 1)
    # nbrs = Map.get(strctr, node)
    # # IO.inspect(nodes)

    # strctr = del_elem(nbrs, strctr, node)

    # strctr = Map.delete(strctr, node)
    # topology = put_elem(topology, 1, strctr)
    # topology

    ds = Map.get(topology, :deleted_set)
    ds = MapSet.put(ds, node)
    topology = Map.put(topology, :deleted_set, ds)
    topology = Map.delete(topology, node)
    topology
  end

  # defp del_elem([], strctr, _x) do
  #   strctr
  # end

  # defp del_elem([nbr | nbrs], strctr, node) do
  #   strctr =
  #     if nbr != 0 do
  #       new_nbrs = Map.get(strctr, nbr)
  #       new_nbrs = new_nbrs -- [node]
  #       strctr = Map.put(strctr, nbr, new_nbrs)
  #       del_elem(nbrs, strctr, node)
  #     else
  #       strctr
  #     end

  #   strctr
  # end

  defp iterate_list([], topology) do
    topology
  end

  defp iterate_list([node | nodes], topology) do
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
        # nbrs = List.delete_at(nbrs, 0)
        nbrs = MapSet.put(nbrs, node)
        strctr = Map.put(strctr, prev, nbrs)

        new_nbrs = MapSet.new([prev])
        strctr = Map.put(strctr, node, new_nbrs)
        put_elem(topology, 1, strctr)
      end

    # IO.inspect topology
    topology = iterate_list(nodes, topology)
    topology
  end
end
