defmodule Gossip.Application do
  def start_link(caller, args) do
    GenServer.start_link(
      __MODULE__,
      [caller: caller, args: String.to_integer(Enum.at(args, 0))],
      []
    )
  end

  def init(opts) do
    # create topology
    {:ok, topology} = Gossip.Topology.start_link(self())
    # create nodes
    nodes = create_nodes(opts[:args], topology)
    node = Enum.at(nodes, 0)
    # Start tranmitting from a node
    Gossip.Node.transmit_rumour(node)

    state = %{
      topology: topology,
      caller: opts[:caller]
    }

    {:ok, state}
  end

  def handle_info({:network_converged}, state) do
    send(state.caller, {:terminate})
    {:noreply, state}
  end

  defp create_nodes(n, topology) do
    # Create nodes.
    nodes =
      Enum.reduce(1..n, [], fn x, list ->
        {:ok, pid} = Gossip.Node.start_link(x, topology)
        [pid | list]
      end)

    nodes
  end
end
