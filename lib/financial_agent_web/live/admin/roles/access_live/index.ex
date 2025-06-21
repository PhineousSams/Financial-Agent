defmodule FinincialAgentWeb.AccessLive.Index do
  use FinincialAgentWeb, :live_view
  on_mount FinincialAgentWeb.UserLiveAuth

  alias FinincialAgent.Roles
  alias FinincialAgent.Workers.Util.Utils
  alias FinincialAgent.Workers.Util.Helpers
  alias FinincialAgent.Workers.Helpers.PermissionsCheck

  @impl true
  def mount(params, _session, %{assigns: assigns} = socket) do
    if PermissionsCheck.page_access("assign_user_roles", assigns.permits) do
      role = Roles.get_user_role_by_id_preload(params["role"])
      all = Roles.get_permissions_with_groups()

      IO.inspect all, label: "======== all permissions ========="

      socket =
        assign(socket, keep: all)
        |> assign(role: role.id)
        |> assign(all_permissions: all)
        |> assign(:select_all, false)
        |> assign(:user_role, Roles.get_user_role_name_by_id_with_permissions(role))

      {:ok, socket}
    else
      {:ok, redirect(socket, to: ~p"/Admin/dashboard")}
    end
  end

  def group_permissions(permits) do
    permits
    |> Enum.group_by(fn a -> a.group end)
    |> Enum.reduce([], fn {group, permissions}, acc ->
      permits = Enum.map(permissions, fn p -> p.name end)
      acc ++ [%{name: group, permits: permits}]
    end)
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event(target, params, socket), do: handle_event_switch(target, params, socket)

  def handle_event_switch(target, params, socket) do
    case target do
      "search" -> search(params, socket)
      "validate" -> validate(params, socket)
      "save" -> save(params, socket)
      "select_all" -> select_all(params, socket)
    end
  end


  def select_all(_params, %{assigns: %{select_all: select_all, all_permissions: all_permissions, user_role: user_role}} = socket) do
    permissions = if select_all, do: [], else: Enum.map(all_permissions, & &1.name)
    updated_user_role = Map.put(user_role, :permissions, permissions)
    {:noreply,
     socket
     |> assign(:user_role, updated_user_role)
     |> assign(:select_all, !select_all)}
  end

  def search(params, socket) do
    filter =
      String.downcase(params["filter"])
      |> String.replace(" ", "_")

    keep_ids = Enum.map(socket.assigns.keep, fn p -> p.id end)

    all_permissions =
      Enum.map(Roles.get_filter_permissions(filter), fn data ->
        if data.id in keep_ids, do: data, else: []
      end)
      |> List.flatten()

    {:noreply,
     socket
     |> put_flash(:info, "Search results for #{params["filter"]}")
     |> assign(all_permissions: all_permissions)}
  end

  def validate(%{"permissions" => permissions} = _params, socket) do
    {:noreply,
     socket
     |> assign(
       :user_role,
       Map.merge(
         socket.assigns.user_role,
         %{permissions: Enum.map(permissions, fn {k, _} -> k end)}
       )
     )}
  end

  def validate(_params, socket) do
    {:noreply,
     socket
     |> assign(:user_role, Map.merge(socket.assigns.user_role, %{permissions: []}))}
  end

  def save(_params, %{assigns: assigns} = socket) do
    assigns.user_role.permissions
    |> Roles.update_user_role_permissions(assigns.user_role.id, assigns.current_user)
    |> case do
      {:ok, %{role: role}} ->
        {:noreply, put_flash(socket, :info, "#{role.name} role permissions updated successfully")}

      {:error, _failed_operation, failed_value, _changes_so_far} ->
        reason = Utils.traverse_errors(failed_value.errors)
        {:noreply, put_flash(socket, :error, reason)}
    end
  end
end
