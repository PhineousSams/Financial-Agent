defmodule FinincialToolWeb.RoleLive.Redirect do
  @moduledoc false
  use FinincialToolWeb, :live_view
  on_mount FinincialToolWeb.UserLiveAuth

  @impl true
  def mount(_params, _session, socket) do
    {:ok, push_redirect(socket, to: ~p"/Admin/dashboard")}
  end
end
