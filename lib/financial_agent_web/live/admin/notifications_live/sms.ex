defmodule FinincialAgentWeb.NotificationsLive.Sms do
  use FinincialAgentWeb, :live_view

  alias FinincialAgent.Notifications
  alias FinincialAgentWeb.Helps.PaginationControl, as: Control

  @impl true
  def mount(_params, _session, socket) do
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
    if connected?(socket), do: send(self(), {:get_sms, params})

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
      :get_sms ->
        get_sms(socket, %{"sort_direction" => "desc", "sort_field" => "id"})

      {:get_sms, params} ->
        get_sms(socket, params)
    end
  end

  defp get_sms(socket, params) do
    data = Notifications.get_sms_logs(Control.create_table_params(socket, params))

    {
      :noreply,
      assign(socket, :data, data)
      |> assign(data_loader: false)
      |> assign(params: params)
    }
  end
end
