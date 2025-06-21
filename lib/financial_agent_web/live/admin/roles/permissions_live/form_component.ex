defmodule FinancialAgentWeb.PermissionsLive.FormComponent do
  @moduledoc false
  use FinancialAgentWeb, :live_component

  alias FinancialAgent.Logs
  alias FinancialAgent.Repo
  alias FinancialAgent.Roles
  alias FinancialAgent.Roles.Permissions
  alias FinancialAgent.Workers.Util.Utils
  alias FinancialAgent.Workers.Util.Cache

  @impl true
  def update(%{permission: permission, title: title} = assigns, socket) do
    changeset = Roles.change_permissions(permission)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:title, title)
     |> assign(:groups, Roles.get_permission_groups())
     |> assign(:form, to_form(changeset))}
  end

  @impl true
  def handle_event(target, params, socket), do: handle_event_switch(target, params, socket)

  def handle_event_switch(target, params, socket) do
    case target do
      "validate" -> validate(params, socket)
      "save" -> save_permission(socket, socket.assigns.action, params)
    end
  end

  def validate(params, socket) do
    changeset =
      socket.assigns.permission
      |> Roles.change_permissions(params["permissions"])
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  defp save_permission(socket, type, params) do
    params = Utils.to_atomic_map(params)

    handle_permission(socket, params, type)
    |> case do
      {:ok, message} ->
        socket =
          socket
          |> put_flash(:info, message)
          |> push_redirect(to: socket.assigns.return_to)

        {:noreply, socket}

      {:error, reason} ->
        socket =
          socket
          |> put_flash(:error, reason)
          |> push_redirect(to: socket.assigns.return_to)

        {:noreply, socket}
    end
  end

  defp handle_permission(%{assigns: assigns} = socket, %{permissions: permissions}, :new) do
    Cache.put(assigns, :assigns)
    permission =
      Map.merge(permissions, %{created_by: assigns.user.id, status: "PENDING_APPROVAL"})

    Ecto.Multi.new()
    |> Ecto.Multi.insert(:permission, Permissions.changeset(%Permissions{}, permission))
    |> Ecto.Multi.merge(fn %{permission: permission} ->
      Logs.log_session(
        socket,
        "Create PermissionS [#{permission.name}]",
        "CREATE",
        permission,
        "Permissions Management"
      )
    end)
    |> Repo.transaction()
    |> case do
      {:ok, _multi} ->
        {:ok, "Permission created successfully"}

      {:error, _failed_operation, failed_value, _changes_so_far} ->
        reason = Utils.traverse_errors(failed_value.errors)
        {:error, reason}
    end
  end

  defp handle_permission(%{assigns: assigns} = _socket, %{permissions: permissions}, :edit) do
    permission = Map.merge(permissions, %{updated_by: assigns.user.id})

    Ecto.Multi.new()
    |> Ecto.Multi.update(:permission, Permissions.changeset(assigns.permission, permission))
    |> Repo.transaction()
    |> case do
      {:ok, _multi} ->
        {:ok, "Permision editted Successfully."}

      {:error, _failed_operation, failed_value, _changes_so_far} ->
        reason = Utils.traverse_errors(failed_value.errors)
        {:error, reason}
    end
  end
end
