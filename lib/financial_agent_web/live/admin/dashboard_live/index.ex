defmodule FinincialAgentWeb.DashboardLive.Index do
  use FinincialAgentWeb, :live_view
  alias FinincialAgent.Companies
  alias FinincialAgent.Accounts

  @impl true
  def mount(_params, _session, %{assigns: _assigns} = socket) do
    Task.async(fn -> FinincialAgent.SetUps.SetUpPermissions.permits() end)
    {:ok,
     socket
     |> assign(:title, "Dashboard")
     |> assign(:count_users, Accounts.count_users())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    if connected?(socket), do: send(self(), {:list_users, params})

    {
      :noreply,
      socket
      |> assign(:params, params)
      |> apply_action(socket.assigns.live_action, params)
    }
  end

  defp apply_action(socket, :index, _) do
    socket
    |> assign(show_modal: false)
    |> assign(:page_title, "Dashboard")
  end

  defp apply_action(socket, :profile, _params) do
    socket
    |> assign(:page_title, "My Profile")
    |> assign(:user, socket.assigns.user)
  end
end
