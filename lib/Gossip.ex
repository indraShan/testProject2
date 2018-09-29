# Represents a node in the network.
# Can receive from and send data to other nodes in the network.
# Both receive and send processes work on the same
# thread/actor i.e. read may get blocked on write and vice versa.
# revisit if required.
defmodule Gossip.Node do
  @timer_interval 10

  def start_link(label, application, algo) do
    GenServer.start(__MODULE__, [label: label, application: application, algo: algo], [])
  end

  def init(opts) do
    {:ok, handler} = Gossip.RumourHandler.start_link(opts[:label], opts[:algo])

    state = %{
      label: opts[:label],
      rumourHandler: handler,
      terminated: false,
      application: opts[:application]
    }

    {:ok, state}
  end

  def transmit_rumour(pid, topology) do
    GenServer.cast(pid, {:transmit_rumour, topology})
  end

  def recv_rumour(pid, rumour, topology) do
    GenServer.cast(pid, {:recv_rumour, rumour, topology})
  end

  def handle_info(:re_transmit_rumour, state) do
    Gossip.Node.transmit_rumour(self(), state.topology)
    {:noreply, state}
  end

  def handle_cast({:transmit_rumour, topology}, state) do
    if state.terminated == true do
      if Map.has_key?(state, :timer) do
        :timer.cancel(state.timer)
      end

      {:noreply, state}
    else
      # Update the state to include the topology received
      new_state = Map.put(state, :topology, topology)
      new_state.rumourHandler |> Gossip.RumourHandler.hot_rumour() |> do_broadcast(new_state)

      if Map.has_key?(new_state, :timer) do
        :timer.cancel(new_state.timer)
      end

      timer = Process.send_after(self(), :re_transmit_rumour, @timer_interval)
      {:noreply, Map.put(new_state, :timer, timer)}
    end
  end

  def handle_cast({:recv_rumour, rumour, topology}, state) do
    if state.terminated == true do
      if Map.has_key?(state, :timer) do
        :timer.cancel(state.timer)
      end

      {:noreply, state}
    else
      new_state = Map.put(state, :topology, topology)
      {terminate, map} = new_state.rumourHandler |> Gossip.RumourHandler.handle_rumour(rumour)

      IO.puts("Node #{state.label} received a brodcast from #{rumour.label}.")

      updated_state =
        if terminate == true do
          if Map.has_key?(new_state, :timer) do
            :timer.cancel(new_state.timer)
          end

          send(state.application, {:node_terminated})

          # IO.puts(
          #   "Node #{state.label} Count = #{map.count}, Ratio = #{map.ratio}, Rounds = #{
          #     map.rounds
          #   }"
          # )

          Map.put(new_state, :terminated, true)
        else
          Gossip.Node.transmit_rumour(self(), new_state.topology)
          new_state
        end

      {:noreply, updated_state}
    end
  end

  def do_broadcast(rumour, state) do
    # Get neighbour from topology. send rumour
    neighbour = Gossip.Topology.neighbour_for_node(state.topology, self())
    # IO.puts("Broadcasting rumour from node #{state.label}")
    Gossip.Node.recv_rumour(neighbour, rumour, state.topology)
  end
end
