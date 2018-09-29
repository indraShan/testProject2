defmodule Gossip.LineTopology do
  def start_link() do
    Agent.start_link(fn -> {} end)
  end

  def register_node(pid, node) do
    structure = Agent.get(pid, fn tup -> tup end)

    if length(structure) == 0 do
      ptrs = %ptr_struct{}
      Agent.update(pid, fn tup -> put_elem(tup, 0, node) end)
      Agent.update(pid, fn tup -> put_elem(tup, 1, %{node => ptrs}) end)
    else
      search_node = elem(structure, 0)
      Agent.update(pid, fn tup -> put_elem(tup, 0, node) end)
      ptrs = elem(structure, 1)[search_node]
    end

    {:ok}
  end

  def debug_node(pid) do
    Agent.get(pid, fn list -> list end)
  end

  def neighbour_for_node(pid, node) do
    nodes = Agent.get(pid, fn list -> list end)
    random = Enum.random(0..(length(nodes) - 1))
    neighbour = Enum.at(nodes, random)

    neighbour =
      if neighbour == node do
        neighbour_for_node(pid, node)
      else
        neighbour
      end

    neighbour
  end
end

defmodule ptr_struct do
  defstruct prev: 0, next: 0
end
