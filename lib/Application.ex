defmodule Gossip.Application do
  @push_sum_algo "push-sum"
  @gossip_algo "gossip"
  def start_link(caller, args) do
    GenServer.start_link(
      __MODULE__,
      [caller: caller, args: args],
      []
    )
  end

  def init(opts) do
    # create nodes
    number_of_nodes = String.to_integer(Enum.at(opts[:args], 0))
    # Topology ignored for now.
    _ = Enum.at(opts[:args], 1)
    # Algo defaults to gossip, unless it is push_sum
    algo =
      if Enum.at(opts[:args], 2) != @push_sum_algo do
        @gossip_algo
      else
        @push_sum_algo
      end

    nodes = create_nodes(number_of_nodes, algo)
    topology = Gossip.Topology.create_structure(nodes)
    node = Enum.at(nodes, 0)
    # Start tranmitting from a node
    Gossip.Node.transmit_rumour(node, topology)

    state = %{
      topology: topology,
      caller: opts[:caller],
      nodes_count: number_of_nodes
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

  defp create_nodes(n, algo) do
    # Create nodes.
    nodes =
      Enum.reduce(1..n, [], fn x, list ->
        {:ok, pid} = Gossip.Node.start_link(x, self(), algo)
        [pid | list]
      end)

    nodes
  end
end
