defmodule Gossip.Application do
  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start, [opts]},
      type: :worker,
      restart: :permanent,
      shutdown: 500
    }
  end

  def start(args) do
    Task.start(fn -> startup(Enum.at(args, 0), Enum.at(args, 1)) end)
  end

  defp startup(_caller, nodes) do
  end
end
