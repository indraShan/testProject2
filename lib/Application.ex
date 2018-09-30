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
    topology_type = Enum.at(opts[:args], 1)
    # Algo defaults to gossip, unless it is push_sum
    algo =
      if Enum.at(opts[:args], 2) != @push_sum_algo do
        @gossip_algo
      else
        @push_sum_algo
      end

    # modify number_of_nodes to account for the toplpgy
    number_of_nodes =
      case topology_type do
        "torus" ->
          nums = round(:math.ceil(:math.sqrt(number_of_nodes)))
          nums * nums

        "grid3d" ->
          root = :math.pow(number_of_nodes, 1 / 3)
          num = round(:math.ceil(root))
          num * num * num

        _ ->
          number_of_nodes
      end

    nodes = create_nodes(number_of_nodes, algo, topology_type)
    topology = Gossip.Topology.create_topology(topology_type, nodes)

    state = %{
      topology: topology,
      caller: opts[:caller],
      nodes: nodes
    }

    send(self(), {:start_gossip})

    {:ok, state}
  end

  # Called by node as they terminate.
  # Decide when to terminated the whole thing and go home.
  def handle_info({:node_terminated, node}, state) do
    nodes = List.delete(state.nodes, node)

    if length(nodes) == 1 do
      send(state.caller, {:terminate})
    end

    {:noreply, Map.put(state, :nodes, nodes)}
  end

  # Called from init. Just once to start the gossip.
  def handle_info({:start_gossip}, state) do
    # Get a random node
    node = Enum.at(state.nodes, Enum.random(0..(length(state.nodes) - 1)))
    # Start tranmitting from the chosen node
    Gossip.Node.transmit_rumour(node, state.topology)
    {:noreply, state}
  end

  defp create_nodes(n, algo, topology_type) do
    # Create nodes.
    nodes =
      Enum.reduce(1..n, [], fn x, list ->
        {:ok, pid} = Gossip.Node.start_link(x, self(), algo, topology_type)
        [pid | list]
      end)

    nodes
  end
end
