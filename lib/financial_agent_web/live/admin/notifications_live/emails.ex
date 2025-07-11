defmodule FinancialAgentWeb.Admin.NotificationsLive.Emails do
  use FinancialAgentWeb, :live_view

  alias FinancialAgent.Notifications
  alias FinancialAgentWeb.Helps.PaginationControl, as: Control

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
    if connected?(socket), do: send(self(), {:get_emails, params})

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
      :get_emails ->
        get_emails(socket, %{"sort_direction" => "desc", "sort_field" => "id"})

      {:get_emails, params} ->
        get_emails(socket, params)
    end
  end

  defp get_emails(socket, params) do
    data = Notifications.get_all_emails(Control.create_table_params(socket, params))

    {
      :noreply,
      assign(socket, :data, data)
      |> assign(data_loader: false)
      |> assign(params: params)
    }
  end
end
