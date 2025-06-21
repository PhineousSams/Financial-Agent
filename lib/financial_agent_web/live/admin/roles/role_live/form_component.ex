defmodule FinancialAgentWeb.RoleLive.FormComponent do
  @moduledoc false
  use FinancialAgentWeb, :live_component

  alias FinancialAgent.Repo
  alias FinancialAgent.Logs
  alias FinancialAgent.Roles
  alias FinancialAgent.Roles.UserRole
  alias FinancialAgent.Workers.Util.Utils
  alias FinancialAgent.Workers.Util.Cache

  @impl true
  def update(%{user_role: user_role, title: title} = assigns, socket) do
    changeset = Roles.change_user_role(user_role)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:title, title)
     |> assign(:form, to_form(changeset))}
  end

  @impl true
  def handle_event(target, params, socket), do: handle_event_switch(target, params, socket)

  def handle_event_switch(target, params, socket) do
    case target do
      "validate" -> validate(params, socket)
      "save" -> save_role(socket, socket.assigns.action, params)
    end
  end

  def validate(params, socket) do
    changeset =
      socket.assigns.user_role
      |> Roles.change_user_role(params["user_role"])
      |> Map.put(:action, :validate)

    {:noreply,
     assign(socket, :changeset, changeset)
     |> assign(:form, to_form(changeset))}
  end

  defp save_role(socket, type, params) do
    params = Utils.to_atomic_map(params)

    handle_role(socket, params, type)
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

  defp handle_role(%{assigns: assigns} = socket, %{user_role: user_role}, :new) do
    Cache.put(assigns, :assigns)

    user_role =
      Map.merge(user_role, %{
        editable: true,
        created_by: assigns.user.id,
        status: "PENDING_CONFIGURATION"
      })

    Ecto.Multi.new()
    |> Ecto.Multi.insert(:role, UserRole.changeset(%UserRole{}, user_role))
    |> Ecto.Multi.merge(fn %{role: role} ->
      Logs.log_session(
        socket,
        "Create User Role [#{role.name}]",
        "CREATE",
        role,
        "Role Management"
      )
    end)
    |> Repo.transaction()
    |> case do
      {:ok, _multi} ->
        {:ok, "User Role created successfully"}

      {:error, _failed_operation, failed_value, _changes_so_far} ->
        reason = Utils.traverse_errors(failed_value.errors)
        {:error, reason}
    end
  end

  defp handle_role(%{assigns: assigns}, %{user_role: user_role}, :edit) do
    user_role = Map.merge(user_role, %{updated_by: assigns.user.id})

    Ecto.Multi.new()
    |> Ecto.Multi.update(:role, UserRole.changeset(assigns.user_role, user_role))
    |> Repo.transaction()
    |> case do
      {:ok, _multi} ->
        {:ok, "User Role editted Successfully."}

      {:error, _failed_operation, failed_value, _changes_so_far} ->
        reason = Utils.traverse_errors(failed_value.errors)
        {:error, reason}
    end
  end
end
