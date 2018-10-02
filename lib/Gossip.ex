# Represents a node in the network.
# Can receive from and send data to other nodes in the network.
# Both receive and send processes work on the same
# thread/actor i.e. read may get blocked on write and vice versa.
# revisit if required.
defmodule Gossip.Node do
  @timer_interval 500

  def start_link(label, application, algo, topology_type) do
    GenServer.start(
      __MODULE__,
      [label: label, application: application, algo: algo, topology_type: topology_type],
      []
    )
  end

  def init(opts) do
    {:ok, handler} = Gossip.RumourHandler.start_link(opts[:label], opts[:algo], self())

    state = %{
      label: opts[:label],
      rumourHandler: handler,
      terminated: false,
      infected: false,
      application: opts[:application],
      topology_type: opts[:topology_type]
    }

    {:ok, state}
  end

  def transmit_rumour(pid, topology) do
    GenServer.cast(pid, {:transmit_rumour, topology})
  end

  # Called internally
  defp re_transmit_rumour(pid, topology, rumour) do
    GenServer.cast(pid, {:re_transmit_rumour, topology, rumour})
  end

  def recv_rumour(pid, rumour, topology) do
    GenServer.cast(pid, {:recv_rumour, rumour, topology})
  end

  # Gets called when someone we sent the rumour to is no longer active.
  # We should remove that node from our topology and retranmit the
  # rumour to someone else.
  def handle_info({:remove_from_topology, sender, rumour}, state) do
    updated_state =
      Map.put(
        state,
        :topology,
        Gossip.Topology.remove_node(state.topology_type, state.topology, sender)
      )

    # IO.inspect(state.topology)
    re_transmit_rumour(self(), state.topology, rumour)

    # IO.puts("Number of nodes = #{Gossip.Topology.debug_node_count(state.topology_type, state.topology)}, after removal = #{Gossip.Topology.debug_node_count(state.topology_type, updated_state.topology)}")

    {:noreply, updated_state}
  end

  def handle_cast({:re_transmit_rumour, _topology, rumour}, state) do
    if state.terminated == true do
      {:noreply, state}
    else
      do_broadcast(rumour, state)
      {:noreply, state}
    end
  end

  def handle_info({:continue_gossip}, state) do
    Gossip.Node.transmit_rumour(self(), state.topology)
    {:noreply, state}
  end

  def handle_info({:transmit_again}, state) do
    # IO.puts("Again called.")
    Gossip.Node.transmit_rumour(self(), state.topology)
    {:noreply, state}
  end

  # Will be called once from the App.
  # Rest of the calls will be from other nodes.
  # Once the flow comes to this point - assume that we have a neighour to broadcast.
  def handle_cast({:transmit_rumour, topology}, state) do
    if state.terminated == true do
      # This should never happen.
      # This nodes termination gets handled in recv_rumour. So whoeever sent
      # the rumour to this node already knows that this node is terminated.

      {:noreply, state}
    else
      # Update the state to include the topology received
      new_state = Map.put(state, :topology, topology)

      new_state =
        new_state.rumourHandler |> Gossip.RumourHandler.hot_rumour() |> do_broadcast(new_state)

      {:noreply, new_state}
    end
  end

  defp cancelTimer(state) do
    if Map.has_key?(state, :timer) do
      Process.cancel_timer(state.timer)
    end
  end

  # Gets called when this node receives a rumour from someone else
  def handle_cast({:recv_rumour, rumour, topology}, state) do
    # Cancel any existing timers, as we would be transmitting again as a result
    # of this receive.
    cancelTimer(state)

    if state.terminated == true do
      # Ask the sender to remove this node from its topology.
      # And forward the same rumour to someone else.
      sender = rumour.sender
      send(sender, {:remove_from_topology, self(), rumour})
      {:noreply, state}
    else
      new_state = Map.put(state, :topology, topology)

      new_state =
        if new_state.infected == false do
          send(new_state.application, {:node_infected, self()})
          new_state |> Map.put(:infected, true)
        else
          new_state
        end

      {terminate, map} = new_state.rumourHandler |> Gossip.RumourHandler.handle_rumour(rumour)

      # IO.puts("Node #{state.label} received a brodcast from #{rumour.label}.")

      updated_state =
        if terminate == true do
          send(state.application, {:node_terminated, self()})

          # Ask the sender to continue gossip
          sender = rumour.sender
          send(sender, {:continue_gossip})

          # IO.puts(
          #   "Node #{state.label} Count = #{map.count}, Ratio = #{map.ratio}, Rounds = #{
          #     map.rounds
          #   }"
          # )

          # kb
          # IO.puts "Node #{state.label}...................Reached Level 10"
          Map.put(new_state, :terminated, true)
        else
          # kb
          # IO.puts(
          #   "Node #{state.label} Count = #{map.count}, Ratio = #{map.ratio}, Rounds = #{
          #     map.rounds
          #   }"
          # )
          Gossip.Node.transmit_rumour(self(), new_state.topology)
          new_state
        end

      {:noreply, updated_state}
    end
  end

  def do_broadcast(rumour, state) do
    if state.terminated == true do
      state
    else
      {neighbour, topology} =
        Gossip.Topology.neighbour_for_node(state.topology_type, state.topology, self())

      state = Map.put(state, :topology, topology)

      if neighbour != nil do
        # IO.puts("Broadcasting rumour from node #{state.label}")
        # size = map_size(state.topology)-1

        # kb
        # IO.puts "Found neighbour for #{state.label}"
        # IO.inspect state.topology
        Gossip.Node.recv_rumour(neighbour, rumour, state.topology)
        cancelTimer(state)
        timer = Process.send_after(self(), {:transmit_again}, @timer_interval)
        Map.put(state, :timer, timer)
        # state
      else
        # size = map_size(state.topology)-1

        # kb
        # IO.puts("#{state.label} cannot find neighbour = ")
        # IO.inspect state.topology
        send(state.application, {:node_cannot_find_neighbour, self()})
        Map.put(state, :terminated, true)
      end
    end
  end
end
