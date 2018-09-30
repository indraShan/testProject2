defmodule Gossip.Rand2DTopology do
  def create_structure(nodes) do
    # should get numNodes, list of nodes and topology
    # For now just the torus network.
    # But from here we can return whatever we want.

    node_mapping = %{}

    node_mapping = Map.put(node_mapping, :points, MapSet.new([]))
    node_mapping = plot_nodes(nodes, node_mapping)
    # IO.inspect node_mapping
    # mtrx = Enum.chunk_every(nodes, size, size)

    strctr = %{}
    # strctr = iterate_row(mtrx, strctr, 0, 0, size - 1)
    strctr = populate_nbrs(nodes, nodes, node_mapping, strctr)
    strctr
  end

  # This method gets called with the exact parameter that was returned from the
  # create_structure method
  def neighbour_for_node(topology, node) do
    mpset = Map.get(topology, node)

    neighbour =
      if MapSet.size(mpset) > 0 do
        Enum.random(mpset)
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
    mp = Map.get(topology, node)
    nodes = MapSet.to_list(mp)
    IO.inspect(nodes)

    topology = del_elem(nodes, topology, node)

    topology = Map.delete(topology, node)
    topology
  end

  defp del_elem([], topology, _x) do
    topology
  end

  defp del_elem([node | nodes], topology, x) do
    nbrs = Map.get(topology, node)
    nbrs = MapSet.delete(nbrs, x)
    topology = Map.put(topology, node, nbrs)

    topology = del_elem(nodes, topology, x)
    topology
  end

  defp plot_nodes([], node_mapping) do
    node_mapping
  end

  defp plot_nodes([node | nodes], node_mapping) do
    x = Float.ceil(:rand.uniform(), 3)
    y = Float.ceil(:rand.uniform(), 3)

    mpset = Map.get(node_mapping, :points)
    # IO.puts "Printing on top"
    # IO.inspect mpset

    node_mapping =
      if MapSet.member?(mpset, {x, y}) == false do
        # IO.puts "came here"
        points_set = Map.get(node_mapping, :points)
        points_set = MapSet.put(points_set, {x, y})
        Map.put(node_mapping, :points, points_set)
      else
        # IO.puts "else block"
        plot_nodes(node, node_mapping)
      end

    node_mapping = Map.put(node_mapping, node, {x, y})
    # IO.inspect node_mapping
    node_mapping = plot_nodes(nodes, node_mapping)
    node_mapping
  end

  defp populate_nbrs([], _nodes, _node_mapping, strctr) do
    strctr
  end

  defp populate_nbrs([node | rem], nodes, node_mapping, strctr) do
    point = Map.get(node_mapping, node)

    nbrs =
      Enum.filter(nodes, fn x ->
        coordinates = Map.get(node_mapping, x)
        x_diff = elem(coordinates, 0) - elem(point, 0)
        y_diff = elem(coordinates, 1) - elem(point, 1)
        distance = :math.sqrt(x_diff * x_diff + y_diff * y_diff)
        # IO.puts " d = #{distance}"
        if(x != node and distance <= 0.1) do
          x
        end
      end)

    # IO.inspect nbrs
    mp = MapSet.new(nbrs)
    strctr = Map.put(strctr, node, mp)
    strctr = populate_nbrs(rem, nodes, node_mapping, strctr)
    strctr
  end
end
