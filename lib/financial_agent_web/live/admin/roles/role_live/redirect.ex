defmodule FinincialAgentWeb.RoleLive.Redirect do
  @moduledoc false
  use FinincialAgentWeb, :live_view
  on_mount FinincialAgentWeb.UserLiveAuth

  @impl true
  def mount(_params, _session, socket) do
    {:ok, push_redirect(socket, to: ~p"/Admin/dashboard")}
  end
end
