defmodule FinancialAgentWeb.Admin.SessionLogsLive.Index do
  use FinancialAgentWeb, :live_view

  alias FinancialAgent.Logs
  alias FinancialAgentWeb.Helps.PaginationControl, as: Control

  @impl true
  def mount(_params, _session, %{assigns: _assigns} = socket) do
    socket =
      assign(socket, :data_loader, true)
      |> assign(:data, [])
      |> assign(:info_modal, false)
      |> assign(error_modal: false)
      |> assign(error_message: "")
      |> assign(success_modal: false)
      |> Control.order_by_composer()
      |> Control.i_search_composer()

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    if connected?(socket), do: send(self(), {:get_logs, params})

    {
      :noreply,
      socket
      |> assign(:params, params)
    }
  end

  @impl true
  def handle_info(data, socket), do: handle_info_switch(socket, data)

  defp handle_info_switch(socket, data) do
    case data do
      :get_logs ->
        get_logs(socket, %{"sort_direction" => "desc", "sort_field" => "id"})

      {:get_logs, params} ->
        get_logs(socket, params)
    end
  end

  defp get_logs(socket, params) do
    data = Logs.session_logs(Control.create_table_params(socket, params))

    {
      :noreply,
      assign(socket, :data, data)
      |> assign(data_loader: false)
      |> assign(params: params)
    }
  end

  @impl true
  def handle_event("iSearch", params, socket) do
    data = Logs.get_user_logs(params)

    {
      :noreply,
      assign(socket, :data, data)
      |> assign(data_loader: false)
      |> assign(params: params)
    }
  end
end
