defmodule Gossip.Mailbox do
  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start, [opts]},
      type: :worker,
      restart: :permanent,
      shutdown: 500
    }
  end

  def start(opts) do
    Task.start(fn -> wait(opts[:node], opts[:label]) end)
  end

  defp wait(node, label) do
    receive do
      {:rumour_broadcast, rumour} ->
        Gossip.Node.recv_rumour(node, rumour)
        wait(node, label)
    end
  end
end
