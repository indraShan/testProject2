defmodule Starter do
  use Application

  @doc """
  Starts the app by starting a supervisor and then waits
  until a :done message is received back. This ensures
  that the application does not get killed abruptly.
  """
  def start(_type, _args) do
    {:ok, app} = Gossip.AppSupervisor.start_link(self(), System.argv())
    waitForResult()
    {:ok, app}
  end

  def waitForResult() do
    receive do
      {:terminate} -> IO.puts("Done")
    end
  end
end
