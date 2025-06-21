defmodule FinincialTool.Workers.Util.Cal do
  def get_calender(year) do
    Enum.reduce(1..12, %{}, fn month, acc ->
      first_day_of_month = Date.from_erl!({year, month, 1})
      days_in_month = :calendar.last_day_of_the_month(year, month)
      first_day_of_week = Date.day_of_week(first_day_of_month)

      days_grid = format_days_for_grid(first_day_of_week, days_in_month)
      Map.put(acc, month, days_grid)
    end)
  end

  defp format_days_for_grid(start_day, days_in_month) do
    empty_slots = if(start_day == 7, do: 0, else: start_day)
    # Create empty slots for days before the first day of the month.
    leading_empty_days = List.duplicate(nil, empty_slots)

    # Create a list of all days in the month.
    month_days = Enum.to_list(1..days_in_month)

    # Combine the leading empty slots with the actual days.
    all_days = leading_empty_days ++ month_days

    # Calculate the number of empty slots needed after the last day.
    total_slots = Enum.count(all_days)
    trailing_slots = 7 - rem(total_slots, 7)
    trailing_slots = if trailing_slots == 7, do: 0, else: trailing_slots

    # Append empty slots for days after the last day of the month.
    all_days = all_days ++ List.duplicate(nil, trailing_slots)

    # Group all days into weeks.
    Enum.chunk_every(all_days, 7)
  end
end
