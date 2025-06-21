defmodule FinancialAgentWeb.Admin.ConfigsLive.Index do
  use FinancialAgentWeb, :live_view

  alias FinancialAgent.Settings
  alias FinancialAgent.Settings.ConfigSettings
  alias FinancialAgentWeb.Helps.PaginationControl, as: Control

  @impl true
  def mount(_params, _session, socket) do
      socket =
        assign(socket, :data, [])
        |> assign(:data_loader, true)
        |> assign(:error, "")
        |> assign(:error_modal, false)
        |> assign(:show_modal, false)
        |> assign(:info_modal, false)
        |> Control.order_by_composer()
        |> Control.i_search_composer()

      {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    if connected?(socket), do: send(self(), {:list_settings, params})

    {
      :noreply,
      socket
      |> assign(:params, params)
      |> apply_action(socket.assigns.live_action, params)
    }
  end

  defp apply_action(socket, :index, _) do
    socket
    |> assign(:show_modal, false)
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "Add System Setting")
    |> assign(:settings, %ConfigSettings{})
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Settings")
    |> assign(:settings, Settings.get_settings!(id))
  end

  @impl true
  def handle_info(data, socket), do: handle_info_switch(socket, data)

  defp handle_info_switch(socket, data) do
    case data do
      :list_settings ->
        list_settings(socket, %{"sort_direction" => "desc", "sort_field" => "id"})

      {:list_settings, params} ->
        list_settings(socket, params)
    end
  end

  defp list_settings(%{assigns: _assigns} = socket, params) do
    data = Settings.list_settings(Control.create_table_params(socket, params))

    {
      :noreply,
      assign(socket, :data, data)
      |> assign(data_loader: false)
      |> assign(:show_modal, false)
      |> assign(params: params)
    }
  end

  @impl true
  def handle_event(target, value, socket), do: handle_event_switch(target, value, socket)

  defp handle_event_switch(target, params, socket) do
    case target do
      "iSearch" -> list_settings(socket, params)
      "open_modal" -> open_modal(socket)
      "filter" -> list_settings(socket, params)
      "reload" -> {:noreply, push_redirect(socket, to: "/Admin/Configs/management")}
    end
  end

  defp open_modal(socket) do
    {:noreply, assign(socket, show_modal: true, page: "Filter System Settings")}
  end
end
