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
    case topology_type do
      "torus" ->
        nums = round(:math.ceil(:math.sqrt(number_of_nodes)))
        number_of_nodes = nums * nums
      
      "grid3d" ->
        root = :math.pow(number_of_nodes, 1/3)
        num = round(:math.ceil(root))
        number_of_nodes = num*num*num 
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
      printResult(true, state)
      send(state.caller, {:terminate})
    end

    {:noreply, Map.put(state, :nodes, nodes)}
  end

  def handle_info({:node_cannot_find_neighbour, _node}, state) do
    printResult(false, state)
    send(state.caller, {:terminate})

    {:noreply, state}
  end

  # Called from init. Just once to start the gossip.
  def handle_info({:start_gossip}, state) do
    # Get a random node
    node = Enum.at(state.nodes, Enum.random(0..(length(state.nodes) - 1)))
    start_time = :os.system_time(:millisecond)
    # Start tranmitting from the chosen node
    Gossip.Node.transmit_rumour(node, state.topology)
    {:noreply, Map.put(state, :start_time, start_time)}
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

  defp printResult(converged, state) do
    start_time = state.start_time
    end_time = :os.system_time(:millisecond)
    gossip_time = end_time - start_time

    if converged == true do
      IO.puts("Network converged in #{gossip_time} milliseconds")
    else
      IO.puts("Network did not converge. Time spent: #{gossip_time} milliseconds")
    end
  end
end
