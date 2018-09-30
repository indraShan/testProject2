defmodule Gossip.Grid3DTopology do
  def create_structure(nodes) do
    # should get numNodes, list of nodes and topology
    # For now just the torus network.
    # But from here we can return whatever we want.

    root = :math.pow(length(nodes), 1/3)
    size = round(root)
    # IO.puts "grid = #{size} * #{size} * #{size}"
    grid = Enum.chunk_every(nodes, size * size)
    grid = make_grid(grid, [], 0, size)
    # IO.inspect grid

    strctr = %{}
    strctr = iterate_grid(grid, strctr, 0, 0, 0, size - 1)
    strctr
  end

  # This method gets called with the exact parameter that was returned from the
  # create_structure method
  def neighbour_for_node(topology, node) do
    mpset = Map.get(topology, node)

    neighbour = Enum.random(mpset)

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

  defp make_grid(_grid, new_grid, index, size) when index >= size do
    new_grid
  end

  defp make_grid(grid, new_grid, index, size) do
    list = grid |> Enum.at(index)
    new_grid = new_grid ++ [Enum.chunk_every(list, size, size)]
    new_grid = make_grid(grid, new_grid, index + 1, size)
    new_grid
  end

  defp iterate_grid(_grid, strctr, _row, _col, z, size) when z > size do
    IO.puts("ending...")
    strctr
  end

  defp iterate_grid(grid, strctr, row, col, z, size) do
    # mtrx = grid |> Enum.at(z)
    # IO.puts "z = #{z}"
    strctr = iterate_row(grid, strctr, row, col, z, size)

    strctr = iterate_grid(grid, strctr, row, col, z + 1, size)
    strctr
  end

  defp iterate_row(_grid, strctr, row, _col, _z, size) when row > size do
    strctr
  end

  defp iterate_row(grid, strctr, row, col, z, size) do
    # IO.puts "row = #{row}"
    strctr = iterate_col(grid, strctr, row, col, z, size)

    strctr = iterate_row(grid, strctr, row + 1, col, z, size)
    strctr
  end

  defp iterate_col(_grid, strctr, _row, col, _z, size) when col > size do
    strctr
  end

  defp iterate_col(grid, strctr, row, col, z, size) do
    # IO.puts "col = #{col}, z = #{z}"
    # IO.puts "size = #{size}"
    mtrx = grid |> Enum.at(z)
    # IO.inspect grid
    # IO.inspect mtrx
    node = mtrx |> Enum.at(row) |> Enum.at(col)
    # IO.puts "node = #{node}"

    mp = MapSet.new([])

    mp =
      if z - 1 >= 0 do
        element = grid |> Enum.at(z - 1) |> Enum.at(row) |> Enum.at(col)
        # IO.puts "if cond = #{element}"
        MapSet.put(mp, element)
      else
        mp
      end

    mp =
      if z + 1 <= size do
        element = grid |> Enum.at(z + 1) |> Enum.at(row) |> Enum.at(col)
        # IO.puts "if cond = #{element}"
        MapSet.put(mp, element)
      else
        mp
      end

    mp =
      if row - 1 >= 0 do
        element = mtrx |> Enum.at(row - 1) |> Enum.at(col)
        # IO.puts "if cond = #{element}"
        MapSet.put(mp, element)
      else
        mp
      end

    mp =
      if row + 1 <= size do
        element = mtrx |> Enum.at(row + 1) |> Enum.at(col)
        # IO.puts "if cond = #{element}"
        MapSet.put(mp, element)
      else
        mp
      end

    mp =
      if col - 1 >= 0 do
        element = mtrx |> Enum.at(row) |> Enum.at(col - 1)
        # IO.puts "if cond = #{element}"
        MapSet.put(mp, element)
      else
        mp
      end

    mp =
      if col + 1 <= size do
        element = mtrx |> Enum.at(row) |> Enum.at(col + 1)
        # IO.puts "if cond = #{element}"
        MapSet.put(mp, element)
      else
        mp
      end

    strctr = Map.put(strctr, node, mp)
    IO.inspect(mp)
    # IO.inspect strctr

    strctr = iterate_col(grid, strctr, row, col + 1, z, size)
    strctr
  end
end
