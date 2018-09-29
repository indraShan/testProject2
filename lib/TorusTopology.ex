defmodule Gossip.TorusTopology do
  def create_structure(nodes, numNodes) do
    # should get numNodes, list of nodes and topology
    # For now just the torus network.
    # But from here we can return whatever we want.
    size = round(:math.sqrt(numNodes))
    mtrx = Enum.chunk_every(nodes, size, size)
    strctr = %{}
    strctr = iterate_row(mtrx, strctr, 0, 0, size - 1)
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
