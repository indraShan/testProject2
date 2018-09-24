defmodule Gossip.Topology do
  def start_link() do
    Agent.start_link(fn -> [] end)
  end

  def register_node(pid, node) do
    Agent.update(pid, fn list -> [node | list] end)
    {:ok}
  end

  def debug_node(pid) do
    Agent.get(pid, fn list -> list end)
  end

  def neighbour_for_node(pid, node) do
    nodes = Agent.get(pid, fn list -> list end)
    random = Enum.random(0..length(nodes)-1)
    neighbour = Enum.at(nodes, random)
    neighbour = if neighbour == node do
      neighbour_for_node(pid, node)
    else
      neighbour
    end
    neighbour
  end
end
