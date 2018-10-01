defmodule Gossip.TorusTopology do
  def create_structure(nodes) do
    # should get numNodes, list of nodes and topology
    # For now just the torus network.
    # But from here we can return whatever we want.

    numNodes = length(nodes)
    size = round(:math.sqrt(numNodes))
    # IO.puts("size = #{size}")
    mtrx = Enum.chunk_every(nodes, size, size)
    strctr = %{:deleted_set => MapSet.new([])}

    strctr = iterate_row(mtrx, strctr, 0, 0, size - 1)
    # IO.inspect strctr
    IO.puts "Done creating topology"
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
    mpset = Map.get(topology, node)
    deleted_set = Map.get(topology, :deleted_set)

    {neighbour, topology} =
      if MapSet.size(mpset) > 0 do
        {Enum.random(mpset), topology}
      else
        {nil, topology}
      end

    {neighbour, topology} =
      if neighbour != nil && MapSet.member?(deleted_set, neighbour) do
        mpset = MapSet.delete(mpset, neighbour)
        topology = Map.put(topology, node, mpset)
        neighbour_for_node(topology, node)
      else
        {neighbour, topology}
      end

    {neighbour, topology}
  end

  def remove_node(topology, node) do
    # mp = Map.get(topology, node)

    # IO.inspect {node, mp}, label: "Removing node"

    # nodes = MapSet.to_list(mp)
    # IO.inspect(nodes)

    # topology = del_elem(nodes, topology, node)
    ds = Map.get(topology, :deleted_set)
    ds = MapSet.put(ds, node)
    topology = Map.put(topology, :deleted_set, ds)
    topology = Map.delete(topology, node)
    # IO.inspect node, label: "Deleting node"
    topology
  end

  # defp del_elem([], topology, _x) do
  #   topology
  # end

  # defp del_elem([node | nodes], topology, x) do
  #   nbrs = Map.get(topology, node)
  #   nbrs = MapSet.delete(nbrs, x)
  #   topology = Map.put(topology, node, nbrs)

  #   topology = del_elem(nodes, topology, x)
  #   topology
  # end

  defp iterate_col(_mtrx, strctr, _row, col, size) when col > size do
    strctr
  end

  defp iterate_col(mtrx, strctr, row, col, size) do
    # IO.puts "col = #{col}"
    # IO.puts "size = #{size}"

    mp = MapSet.new([])
    node = mtrx |> Enum.at(row) |> Enum.at(col)
    # IO.puts "node = #{node}"

    mp =
      if row - 1 >= 0 do
        element = mtrx |> Enum.at(row - 1) |> Enum.at(col)
        # IO.puts "if cond = #{element}"
        MapSet.put(mp, element)
      else
        element = mtrx |> Enum.at(size) |> Enum.at(col)
        # IO.puts "else cond = #{element}"
        MapSet.put(mp, element)
      end

    mp =
      if row + 1 <= size do
        element = mtrx |> Enum.at(row + 1) |> Enum.at(col)
        # IO.puts "if cond = #{element}"
        MapSet.put(mp, element)
      else
        element = mtrx |> Enum.at(0) |> Enum.at(col)
        # IO.puts "else cond = #{element}"
        MapSet.put(mp, element)
      end

    mp =
      if col - 1 >= 0 do
        element = mtrx |> Enum.at(row) |> Enum.at(col - 1)
        # IO.puts "if cond = #{element}"
        MapSet.put(mp, element)
      else
        element = mtrx |> Enum.at(row) |> Enum.at(size)
        # IO.puts "else cond = #{element}"
        MapSet.put(mp, element)
      end

    mp =
      if col + 1 <= size do
        element = mtrx |> Enum.at(row) |> Enum.at(col + 1)
        # IO.puts "if cond = #{element}"
        MapSet.put(mp, element)
      else
        element = mtrx |> Enum.at(row) |> Enum.at(0)
        # IO.puts "else cond = #{element}"
        MapSet.put(mp, element)
      end

    strctr = Map.put(strctr, node, mp)
    # IO.inspect strctr

    # IO.inspect mp

    strctr = iterate_col(mtrx, strctr, row, col + 1, size)
    strctr
  end

  defp iterate_row(_mtrx, strctr, row, _col, size) when row > size do
    # IO.puts("ending...")
    strctr
  end

  defp iterate_row(mtrx, strctr, row, col, size) do
    # IO.puts "row = #{row}"
    strctr = iterate_col(mtrx, strctr, row, col, size)

    strctr = iterate_row(mtrx, strctr, row + 1, col, size)
    strctr
  end
end
