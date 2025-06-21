defmodule FinincialAgentWeb.ReportController do
  use FinincialAgentWeb, :controller

  alias FinincialAgent.Settings

  def dash_stats(conn, _params) do
    raw_data = Settings.get_dashboard_data()

    dash_chart =
      Enum.find(raw_data, fn p -> p.name == "DASHBOARD_CHART" end).value |> Jason.decode!()

    pie_chart = Enum.find(raw_data, fn p -> p.name == "PIE_CHART" end).value |> Jason.decode!()

    series = dash_chart["series"] ++ [pie_chart]

    data = %{
      dash_chart: Map.replace!(dash_chart, "series", series)
    }

    json(conn, %{data: data})
  end
end
