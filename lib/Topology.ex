defmodule Gossip.Topology do
  def start_link() do
    Agent.start_link(fn -> [] end)
  end

  def register_node(pid, node) do
    Agent.update(pid, fn list -> [node | list] end)
    {:ok}
  end

  def all_nodes(pid) do
    Agent.get(pid, fn list -> list end)
  end

  def neighbour_for_node(pid, node) do
    neighbour =
      Agent.get(pid, fn list ->
        random = Enum.random(0..(length(list) - 1))
        Enum.at(list, random)
      end)

    neighbour =
      if neighbour == node do
        neighbour_for_node(pid, node)
      else
        neighbour
      end

    neighbour
  end
end
