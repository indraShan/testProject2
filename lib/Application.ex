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

    state = %{
      topology: topology,
      caller: opts[:caller],
      nodes: nodes
    }

    send(self(), {:restart_gossip})

    {:ok, state}
  end

  def handle_info({:node_terminated, node}, state) do
    nodes = List.delete(state.nodes, node)

    if length(nodes) == 1 do
      send(state.caller, {:terminate})
    end

    send(self(), {:restart_gossip})
    {:noreply, Map.put(state, :nodes, nodes)}
  end

  def handle_info({:restart_gossip}, state) do
    # Get a random node
    node = Enum.at(state.nodes, Enum.random(0..(length(state.nodes) - 1)))
    # Start tranmitting from the chosen node
    Gossip.Node.transmit_rumour(node, state.topology)

    {:noreply, state}
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
