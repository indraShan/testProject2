defmodule Gossip.RumourHandler do
  @gossip_rumour_termination_count 10
  @push_sum_no_change_rounds_limit 3
  @push_sum_min_difference :math.pow(10, -10)
  @push_sum_algo "push-sum"

  def start_link(label, algo, node) do
    Agent.start_link(fn ->
      %{
        label: label,
        algo: algo,
        s: label,
        count: 0,
        weight: 1,
        ratio: label,
        rounds: 0,
        sender: node
      }
    end)
  end

  def handle_rumour(pid, rumour) do
    map =
      Agent.get_and_update(
        pid,
        fn map ->
          {
            map,
            if map.algo == @push_sum_algo do
              # Update rumour count by 1
              Map.put(map, :count, map.count + 1)
              |> Map.put(
                :rounds,
                if abs(
                     # Update rounds: If the difference between old and new ratio is less than limit == +1
                     # Otherwise reset to zero
                     (Map.get(rumour, :s) + Map.get(map, :s)) /
                       (Map.get(rumour, :weight) + Map.get(map, :weight)) - Map.get(map, :ratio)
                   ) < @push_sum_min_difference do
                  Map.get(map, :rounds) + 1
                else
                  0
                end
              )
              # Update ratio
              |> Map.put(
                :ratio,
                (Map.get(rumour, :s) + Map.get(map, :s)) /
                  (Map.get(rumour, :weight) + Map.get(map, :weight))
              )
              # Update s to add rumours value
              |> Map.put(:s, Map.get(rumour, :s) + Map.get(map, :s))
              # Update weight to add rumours weight
              |> Map.put(:weight, Map.get(map, :weight) + Map.get(rumour, :weight))
            else
              Map.put(map, :count, map.count + 1)
            end
          }
        end
      )

    if map.algo != @push_sum_algo do
      # Gossip
      if map.count >= @gossip_rumour_termination_count do
        {true, map}
      else
        {false, map}
      end
    else
      rumour_s = Map.get(rumour, :s)
      rumour_weight = Map.get(rumour, :weight)
      # Ratio diff
      new_ratio = (rumour_s + map.s) / (rumour_weight + map.weight)
      difference = abs(new_ratio - map.ratio)

      # Difference lesser than limit and number of rounds equal to 2
      if difference < @push_sum_min_difference and
           map.rounds >= @push_sum_no_change_rounds_limit - 1 do
        {true, map}
      else
        {false, map}
      end
    end
  end

  def hot_rumour(pid) do
    map =
      Agent.get_and_update(pid, fn map ->
        {
          map,
          # Update the state to reduce s and weight by half
          map
          |> Map.put(:s, Map.get(map, :s) / 2)
          |> Map.put(:weight, Map.get(map, :weight) / 2)
        }
      end)

    # Forward the half to the neighbour
    map
    |> Map.put(:s, Map.get(map, :s) / 2)
    |> Map.put(:weight, Map.get(map, :weight) / 2)
  end
end
