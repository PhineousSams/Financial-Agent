defmodule FinancialAgentWeb.Admin.ServiceLogsLive.Index do
  use FinancialAgentWeb, :live_view

  alias Phoenix.LiveView.JS
  alias FinancialAgent.Logs
  alias FinancialAgentWeb.Helps.PaginationControl, as: Control

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:data, [])
     |> assign(:data_loader, true)
     |> assign(:show_modal, false)
     |> assign(:selected_log, nil)
     |> Control.order_by_composer()
     |> Control.i_search_composer()
    }
  end

  @impl true
  def handle_params(params, _url, socket) do
    if connected?(socket), do: send(self(), {:esb_logs, params})

    {
      :noreply,
      socket
      |> assign(:params, params)
      |> apply_action(socket.assigns.live_action, params)
    }
  end

  @impl true
  def handle_info(data, socket), do: handle_info_switch(socket, data)

  defp handle_info_switch(socket, data) do
    case data do
      :esb_logs ->
        get_logs(socket, %{"sort_direction" => "desc", "sort_field" => "id"})

      {:esb_logs, params} ->
        get_logs(socket, params)
    end
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Service Logs")
    |> assign(:log, nil)
  end

  @impl true
  def handle_event(target, value, socket), do: handle_event_switch(target, value, socket)

  defp handle_event_switch(target, params, socket) do
    case target do
      "iSearch" -> get_logs(socket, params)
      "reload" -> {:noreply, push_navigate(socket, to: ~p"/mobileBanking/esb-logs")}
      "show_log_details" -> show_log_details(socket, params)
      "filter_modal" -> {:noreply, socket}
      "modal_closed" -> {:noreply, reset_modal(socket)}
    end
  end

  defp show_log_details(socket, %{"id" => id}) do
    try do
      log = Logs.get_service_log!(id)
      {:noreply,
       socket
       |> assign(:selected_log, log)
       |> assign(:show_modal, true)}
    rescue
      Ecto.NoResultsError ->
        {:noreply,
         socket
         |> put_flash(:error, "Log not found")}
    end
  end

  defp reset_modal(socket) do
    socket
    |> assign(:show_modal, false)
    |> assign(:selected_log, nil)
  end

  defp get_logs(%{assigns: _assigns} = socket, params) do
    data = Logs.get_service_logs(Control.create_table_params(socket, params))

    {
      :noreply,
      assign(socket, :data, data)
      |> assign(data_loader: false)
      |> assign(params: params)
    }
  end
end
