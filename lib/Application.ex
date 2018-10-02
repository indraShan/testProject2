defmodule Gossip.Application do
  @push_sum_algo "push-sum"
  @gossip_algo "gossip"
  @termination_convergence_ratio 0.7

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
      no_neighbour_start_nodes: MapSet.new([]),
      topology_type: topology_type,
      topology: topology,
      caller: opts[:caller],
      nodes: MapSet.new(nodes),
      number_of_nodes: number_of_nodes,
      terminated: false,
      lonely_nodes: MapSet.new([]),
      converged_nodes: MapSet.new([]),
      infected_nodes: MapSet.new([])
    }

    send(self(), {:start_gossip})

    {:ok, state}
  end

  def handle_info({:node_infected, node}, state) do
    if MapSet.member?(state.infected_nodes, node) == false and state.terminated == false do
      infected_nodes = state.infected_nodes |> MapSet.put(node)
      updated_state = state |> Map.put(:infected_nodes, infected_nodes)
      {:noreply, updated_state}
    end
  end

  # Called by node as they terminate.
  # Decide when to terminated the whole thing and go home.
  def handle_info({:node_terminated, node}, state) do
    if MapSet.member?(state.converged_nodes, node) == false and state.terminated == false do
      converged_nodes = state.converged_nodes |> MapSet.put(node)
      updated_state = state |> Map.put(:converged_nodes, converged_nodes)

      updated_state =
        if MapSet.member?(updated_state.infected_nodes, node) == true do
          infected_nodes = updated_state.infected_nodes |> MapSet.delete(node)
          updated_state |> Map.put(:infected_nodes, infected_nodes)
        else
          updated_state
        end

      updated_state =
        if MapSet.size(converged_nodes) / state.number_of_nodes >= @termination_convergence_ratio or
             MapSet.size(updated_state.infected_nodes) == 0 do
          send(self(), {:terminate_app})
          updated_state |> Map.put(:terminated, true)
        else
          updated_state
        end

      {:noreply, updated_state}
    else
      {:noreply, state}
    end
  end

  def handle_info({:node_cannot_find_neighbour, node}, state) do
    if MapSet.member?(state.lonely_nodes, node) == false and state.terminated == false do
      lonely_nodes = state.lonely_nodes |> MapSet.put(node)
      updated_state = state |> Map.put(:lonely_nodes, lonely_nodes)

      updated_state =
        if MapSet.member?(updated_state.infected_nodes, node) == true do
          infected_nodes = updated_state.infected_nodes |> MapSet.delete(node)
          updated_state |> Map.put(:infected_nodes, infected_nodes)
        else
          updated_state
        end

      updated_state =
        if MapSet.size(lonely_nodes) / state.number_of_nodes > @termination_convergence_ratio or
             MapSet.size(updated_state.infected_nodes) == 0 do
          send(self(), {:terminate_app})
          updated_state |> Map.put(:terminated, true)
        else
          updated_state
        end

      {:noreply, updated_state}
    else
      {:noreply, state}
    end
  end

  def handle_info({:terminate_app}, state) do
    convergence_ratio = MapSet.size(state.converged_nodes) / state.number_of_nodes

    if convergence_ratio >= @termination_convergence_ratio do
      printResult(true, state, convergence_ratio)
    else
      printResult(false, state, convergence_ratio)
    end

    send(state.caller, {:terminate})
    {:noreply, state}
  end

  # Called from init. Just once to start the gossip.
  def handle_info({:start_gossip}, state) do
    # Get a random node
    node = Enum.random(MapSet.to_list(state.nodes))
    # If the node doesnt have a nighbour, dont start with this node.
    {neighbour, _} = Gossip.Topology.neighbour_for_node(state.topology_type, state.topology, node)

    if neighbour == nil do
      # If we have tried all the nodes by now, just stop.
      if MapSet.size(state.no_neighbour_start_nodes) == state.number_of_nodes do
        printResult(false, state, 0)
        {:noreply, state}
      else
        # Add the current node no_neighbour_start_nodes and continue.
        no_neighbour_start_nodes = state.no_neighbour_start_nodes |> MapSet.put(node)
        updated_state = state |> Map.put(:no_neighbour_start_nodes, no_neighbour_start_nodes)
        # Try again.
        send(self(), {:start_gossip})
        {:noreply, updated_state}
      end
    else
      start_time = :os.system_time(:millisecond)
      # Start tranmitting from the chosen node
      Gossip.Node.transmit_rumour(node, state.topology)
      {:noreply, Map.put(state, :start_time, start_time)}
    end
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

  defp printResult(converged, state, _ratio) do
    start_time = state.start_time
    end_time = :os.system_time(:millisecond)
    gossip_time = end_time - start_time

    if converged == true do
      IO.puts("Network converged in #{gossip_time} milliseconds.")
    else
      IO.puts("Network did not converge. Time spent: #{gossip_time} milliseconds.")
      # kb
      # IO.inspect state.nodes
      # size = length(state.nodes)
      # IO.puts "left = #{size}"
    end
  end
end
