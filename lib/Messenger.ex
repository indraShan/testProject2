defmodule Messenger do
  def start_link(label) do
    Agent.start_link(fn ->
      %{label: label, rumour: '', count: 0}
    end)
  end

  def handle_rumour(pid, rumour) do
    {label, count} =
      Agent.get_and_update(pid, fn map ->
        {
          {map.label, map.count},
          Map.put(map, :rumour, rumour) |> Map.put(:count, map.count + 1)
        }
      end)

    IO.puts("#{label} - current rumour count = #{count + 1}")
    rumour
  end

  def hot_rumour(pid, rumour) do
    Agent.update(pid, fn map -> Map.put(map, :rumour, rumour) end)
    rumour
  end
end
