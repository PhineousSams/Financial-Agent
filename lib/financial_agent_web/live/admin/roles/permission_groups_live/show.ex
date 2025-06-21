# defmodule FinincialAgentWeb.PermissionGroupsLive.Show do
#   use FinincialAgentWeb, :live_component

#   alias FinincialAgent.Roles

#   @impl true
#   def mount(_params, _session, socket) do
#     {:ok, socket}
#   end

#   @impl true
#   def handle_params(%{"id" => id}, _, socket) do
#     {:noreply,
#      socket
#      |> assign(:page_title, page_title(socket.assigns.live_action))
#      |> assign(:permission_groups, Roles.get_permission_groups!(id))}
#   end

#   defp page_title(:view), do: "Show Permission groups"
#   defp page_title(:edit), do: "Edit Permission groups"
# end

defmodule FinincialAgentWeb.PermissionGroupsLive.Show do
  @moduledoc false
  use FinincialAgentWeb, :live_component

  alias FinincialAgent.Roles

  @impl true

  def update(%{group: permission_group, title: title} = assigns, socket) do
    changeset = Roles.change_permission_groups(permission_group)

    table = [
      %{head: "GROUP", value: permission_group.section},
      %{head: "SECTION:", value: permission_group.group}
    ]

    {:ok,
     socket
     |> assign(assigns)
     |> assign(table: table)
     |> assign(:title, title)
     |> assign(:changeset, changeset)
     |> assign(:roles, Roles.list_user_roles())}
  end
end
