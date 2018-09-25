# Represents a node in the network.
# Can receive from and send data to other nodes in the network.
# Both receive and send processes work on the same
# thread/actor i.e. read may get blocked on write and vice versa.
# revisit if required.
defmodule Gossip.Node do
  def start_link(label, topology) do
    GenServer.start(__MODULE__, [label: label, topology: topology], [])
  end

  def init(opts) do
    {:ok, messenger} = Messenger.start_link(opts[:label])
    {:ok, mailbox} = start_mailbox(opts[:label])

    state = %{
      label: opts[:label],
      mailbox: mailbox,
      messenger: messenger,
      topology: opts[:topology]
    }

    Gossip.Topology.register_node(opts[:topology], mailbox)
    {:ok, state}
  end

  def start_mailbox(label) do
    Gossip.Mailbox.start(label: label, node: self())
  end

  def transmit_rumour(pid, rumour) do
    GenServer.cast(pid, {:transmit_rumour, rumour})
  end

  def recv_rumour(pid, rumour) do
    GenServer.cast(pid, {:recv_rumour, rumour})
  end

  def handle_cast({:transmit_rumour, rumour}, state) do
    # Iterate over all my neighbours and send them a message.
    state.messenger |> Messenger.hot_rumour(rumour) |> do_broadcast(state)
    {:noreply, state}
  end

  def handle_cast({:recv_rumour, rumour}, state) do
    state.messenger |> Messenger.handle_rumour(rumour)
    IO.puts("#{state.label} - Received : #{rumour}")
    {:noreply, state}
  end

  def do_broadcast(rumour, state) do
    # Get neighbour from topology. send rumour
    neighbour = Gossip.Topology.neighbour_for_node(state.topology, state.mailbox)
    send(neighbour, {:rumour_broadcast, rumour})
  end
end
