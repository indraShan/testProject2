defmodule Gossip.AppSupervisor do
  use Supervisor

  def start_link(caller, args) do
    Supervisor.start_link(__MODULE__, [caller, args], [])
  end

  def init(args) do
    children = [
      {Gossip.Application, args}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
