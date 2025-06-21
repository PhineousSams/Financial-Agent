defmodule FinancialAgentWeb.RoleLive.Redirect do
  @moduledoc false
  use FinancialAgentWeb, :live_view
  on_mount FinancialAgentWeb.UserLiveAuth

  @impl true
  def mount(_params, _session, socket) do
    {:ok, push_redirect(socket, to: ~p"/Admin/dashboard")}
  end
end
