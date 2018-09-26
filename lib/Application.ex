defmodule Gossip.Application do
  def start_link(caller, args) do
    GenServer.start_link(
      __MODULE__,
      [caller: caller, args: String.to_integer(Enum.at(args, 0))],
      []
    )
  end

  def init(opts) do
    # create nodes
    nodes = create_nodes(opts[:args])
    topology = Gossip.Topology.create_structure(nodes)
    node = Enum.at(nodes, 0)
    # Start tranmitting from a node
    Gossip.Node.transmit_rumour(node, topology)

    state = %{
      topology: topology,
      caller: opts[:caller],
      nodes_count: opts[:args]
    }

    {:ok, state}
  end

  def handle_info({:node_terminated}, state) do
    nodes_count = state.nodes_count - 1

    if nodes_count == 1 do
      send(state.caller, {:terminate})
    end

    {:noreply, Map.put(state, :nodes_count, nodes_count)}
  end

  defp create_nodes(n) do
    # Create nodes.
    nodes =
      Enum.reduce(1..n, [], fn x, list ->
        {:ok, pid} = Gossip.Node.start_link(x, self())
        [pid | list]
      end)

    nodes
  end
end
