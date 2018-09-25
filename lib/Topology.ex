defmodule Gossip.Topology do
  def start_link(caller) do
    Agent.start_link(fn -> %{caller: caller, nodes: []} end)
  end

  def register_node(pid, node) do
    Agent.update(
      pid,
      fn map ->
        list = Map.get(map, :nodes)
        Map.put(map, :nodes, [node | list])
      end
    )

    {:ok}
  end

  def remove_node(pid, node) do
    Agent.update(
      pid,
      fn map ->
        list = Map.get(map, :nodes)
        updated_list = List.delete(list, node)

        if length(updated_list) == 1 do
          IO.puts("Just one node remaining")
          send(Map.get(map, :caller), {:network_converged})
        end

        Map.put(map, :nodes, updated_list)
      end
    )
  end

  def all_nodes(pid) do
    Agent.get(pid, fn map -> Map.get(map, :nodes) end)
  end

  def neighbour_for_node(pid, node) do
    neighbour =
      Agent.get(pid, fn map ->
        list = Map.get(map, :nodes)
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
