defmodule FinincialAgentWeb.AlertsPanelLive.Index do

  use FinincialAgentWeb, :live_view

  alias FinincialAgent.Notifications


  @impl true
  def mount(_params, _session, socket) do
      alerts = Notifications.list_staff_alerts

    date_groups = group_alerts_by_date(alerts)
    {:ok, assign(socket, alerts: alerts, date_groups: date_groups, filter_date: nil)}
  end

  @impl true
  def handle_info(data, socket), do: handle_info_switch(socket, data)

  defp handle_info_switch(socket, data) do
    case data do
      {:alert_created, alert} ->
        handle_alert({:alert_created, alert}, socket)
    end
  end


  @impl true
  def handle_event(target, value, socket), do: handle_event_switch(target, value, socket)

  defp handle_event_switch(target, params, socket) do
    case target do
      "filter" ->
        handle_filter(params, socket)

      "reload_notifications" ->
        {:noreply, push_redirect(socket, to: "/Admin/alerts")}
    end
  end

  defp handle_filter(%{"date" => date}, socket) do
    filter_date = if date == "", do: nil, else: Date.from_iso8601!(date)
    date_groups = group_alerts_by_date(socket.assigns.alerts, filter_date)
    {:noreply, assign(socket, date_groups: date_groups, filter_date: filter_date)}
  end

  defp handle_alert({:alert_created, alert}, socket) do
    updated_alerts = [alert | socket.assigns.alerts]
    date_groups = group_alerts_by_date(updated_alerts, socket.assigns.filter_date)
    {:noreply, assign(socket, alerts: updated_alerts, date_groups: date_groups)}
  end


  defp group_alerts_by_date(alerts, filter_date \\ nil) do
    alerts
    |> Enum.filter(fn alert ->
      filter_date == nil || Date.compare(alert.inserted_at, filter_date) == :eq
    end)
    |> Enum.group_by(fn alert -> alert.inserted_at end)
    |> Enum.sort_by(fn {date, _} -> date end, {:desc, Date})
  end

  defp format_date(date) do
    case Date.compare(date, Date.utc_today()) do
      :eq -> "Today"
      :lt -> Date.to_string(date)
      :gt -> Date.to_string(date)
    end
  end

  defp format_time(datetime) do
    Calendar.strftime(datetime, "%I:%M %p")
  end

end
