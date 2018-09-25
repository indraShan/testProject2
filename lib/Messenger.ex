defmodule Messenger do
  @rumour_termination_count 100
  def start_link(label) do
    Agent.start_link(fn ->
      %{label: label, s: label, count: 0, weight: 1}
    end)
  end

  def handle_rumour(pid, rumour) do
    {label, count} =
      Agent.get_and_update(pid, fn map ->
        {
          {map.label, map.count},
          Map.put(map, :count, map.count + 1)
        }
      end)

    # IO.puts("Current rumour count = #{count + 1} for node #{label}")

    if count + 1 >= @rumour_termination_count do
      {true, count + 1}
    else
      {false, count + 1}
    end
  end

  def hot_rumour(pid) do
    Agent.get(pid, fn map -> map end)
  end
end
