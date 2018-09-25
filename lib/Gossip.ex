# Represents a node in the network.
# Can receive from and send data to other nodes in the network.
# Both receive and send processes work on the same
# thread/actor i.e. read may get blocked on write and vice versa.
# revisit if required.
defmodule Gossip.Node do
  @timer_interval 10

  def start_link(label, topology) do
    GenServer.start(__MODULE__, [label: label, topology: topology], [])
  end

  def init(opts) do
    {:ok, messenger} = Messenger.start_link(opts[:label])

    state = %{
      label: opts[:label],
      messenger: messenger,
      terminated: false,
      topology: opts[:topology]
    }

    Gossip.Topology.register_node(opts[:topology], self())
    {:ok, state}
  end

  def transmit_rumour(pid) do
    GenServer.cast(pid, {:transmit_rumour})
  end

  def recv_rumour(pid, rumour) do
    GenServer.cast(pid, {:recv_rumour, rumour})
  end

  def handle_info(:re_transmit_rumour, state) do
    Gossip.Node.transmit_rumour(self())
    {:noreply, state}
  end

  def handle_cast({:transmit_rumour}, state) do
    if state.terminated == true do
      if Map.has_key?(state, :timer) do
        :timer.cancel(state.timer)
      end

      {:noreply, state}
    else
      state.messenger |> Messenger.hot_rumour() |> do_broadcast(state)

      if Map.has_key?(state, :timer) do
        :timer.cancel(state.timer)
      end

      timer = Process.send_after(self(), :re_transmit_rumour, @timer_interval)
      {:noreply, Map.put(state, :timer, timer)}
    end
  end

  def handle_cast({:recv_rumour, rumour}, state) do
    if state.terminated == true do
      if Map.has_key?(state, :timer) do
        :timer.cancel(state.timer)
      end

      {:noreply, state}
    else
      {terminate, count} = state.messenger |> Messenger.handle_rumour(rumour)

      # IO.puts(
      #   "Node #{state.label} received a brodcast from #{rumour.label}. Message count = #{count}"
      # )

      new_state =
        if terminate == true do
          # IO.puts("Removing #{state.label} from topology")
          if Map.has_key?(state, :timer) do
            :timer.cancel(state.timer)
          end

          Gossip.Topology.remove_node(state.topology, self())
          IO.inspect(length(Gossip.Topology.all_nodes(state.topology)))
          Map.put(state, :terminated, true)
        else
          Gossip.Node.transmit_rumour(self())
          state
        end

      {:noreply, new_state}
    end
  end

  def do_broadcast(rumour, state) do
    # Get neighbour from topology. send rumour
    neighbour = Gossip.Topology.neighbour_for_node(state.topology, self())
    # IO.puts("Broadcasting rumour from node #{state.label}")
    Gossip.Node.recv_rumour(neighbour, rumour)
  end
end
