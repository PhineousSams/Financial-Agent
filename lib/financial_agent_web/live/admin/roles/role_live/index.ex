defmodule FinincialAgentWeb.RoleLive.Index do
  use FinincialAgentWeb, :live_view
  on_mount FinincialAgentWeb.UserLiveAuth

  alias FinincialAgent.Logs
  alias FinincialAgent.Repo
  alias FinincialAgent.Roles
  alias FinincialAgent.Roles.UserRole
  alias FinincialAgent.Workers.Util.Cache
  alias FinincialAgent.Workers.Util.Utils
  alias FinincialAgentWeb.Helps.ErrorHelper
  alias FinincialAgentWeb.Helps.PaginationControl, as: Control
  alias FinincialAgent.Workers.Helpers.PermissionsCheck

  alias FinincialAgentWeb.NotificationLive.{
    ErrorModalLive,
    InfoModalLive,
    SuccessModalLive
  }

  @changeset Roles.change_user_role(%UserRole{})

  @impl true
  def mount(params, session, %{assigns: assigns} = socket) do
    if PermissionsCheck.page_access("access_user_roles", assigns.permits) do
      Task.start(fn ->
        Logs.system_log_session(
          session,
          "Access Access Role Maintenance Page",
          "Access",
          params,
          "Access Role Maintenance",
          assigns.user.id
        )
      end)

      role = get_role(params)

      socket =
        assign(socket, :changeset, @changeset)
        |> assign(:data, [])
        |> assign(:data_loader, true)
        |> assign(:info_modal, false)
        |> assign(error_modal: false)
        |> assign(error_message: "")
        |> assign(success_modal: false)
        |> assign(show_modal: false)
        |> assign(:role, role)
        |> Control.order_by_composer()
        |> Control.i_search_composer()

      {:ok, socket}
    else
      Task.start(fn ->
        Logs.system_log_session(
          session,
          "Access Access Role Maintenance Page Denied due to permissions access",
          "Access Denied",
          params,
          "Access Role Maintenance",
          assigns.current_user.id
        )
      end)

      # {:ok, push_redirect(socket, to: Routes.dashboard_index_path(socket, :index), replace: true)}
      {:ok,
      socket
      |> put_flash(:error, "Unauthorized action: You don't have permission to view this content!")
      |> push_redirect(to: ~p"/", replace: true)}
    end
  end

  defp get_role(%{"role" => role}) do
    Cache.put(role, :role)
    role
  end

  defp get_role(_), do: Cache.get(:role)

  @impl true
  def handle_params(params, _url, socket) do
    if connected?(socket), do: send(self(), {:list_roles, params})

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
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "Add User Roles")
    |> assign(:user_role, %UserRole{})
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit User Role")
    |> assign(:user_role, Roles.get_user_role_by_id(id))
  end

  @impl true
  def handle_info(data, socket), do: handle_info_switch(socket, data)

  defp handle_info_switch(%{assigns: _assigns} = socket, data) do
    case data do
      :list_roles ->
        list_roles(socket, %{"sort_direction" => "desc", "sort_field" => "id"})

      {:list_roles, params} ->
        list_roles(socket, params)

      {:handle_submit, params, _type} ->
        handle_submit(socket, params)

      {:submit, params} ->
        if connected?(socket), do: send(self(), {:handle_submit, params, :submit})
        {:noreply, assign(socket, :info_wording, "Processing")}

      {:approve, params} ->
        if connected?(socket), do: send(self(), {:handle_submit, params, :approve})
        {:noreply, assign(socket, :info_wording, "Processing")}

      {:activate, params} ->
        if connected?(socket), do: send(self(), {:handle_submit, params, :approve})
        {:noreply, assign(socket, :info_wording, "Processing")}

      {:deactivate, params} ->
        if connected?(socket), do: send(self(), {:handle_submit, params, :deactivate})
        {:noreply, assign(socket, :info_wording, "Processing")}

      {InfoModalLive, _, %{action: action, param: params}} ->
        if action == "process" do
          case params["action"] do
            "submit" ->
              if connected?(socket), do: send(self(), {:submit, params})
              {:noreply, assign(socket, :info_wording, "Processing")}

            "activate" ->
              if connected?(socket), do: send(self(), {:activate, params})
              {:noreply, assign(socket, :info_wording, "Processing")}

            "approve" ->
              if connected?(socket), do: send(self(), {:approve, params})
              {:noreply, assign(socket, :info_wording, "Processing")}

            "deactivate" ->
              if connected?(socket), do: send(self(), {:deactivate, params})
              {:noreply, assign(socket, :info_wording, "Processing")}
          end
        else
          {
            :noreply,
            assign(socket, :info_modal, false)
            |> assign(:info_message, "Yes")
            |> assign(:info_wording, "Yes")
          }
        end

      {SuccessModalLive, :button_clicked, _} ->
        {
          :noreply,
          #  push_redirect(socket, to: Routes.role_index_path(socket, :index, assigns.role))}
          push_redirect(socket, to: ~p"/Admin/roles")
        }

      {ErrorModalLive, :button_clicked, _} ->
        {:noreply, push_redirect(socket, to: ~p"/Admin/roles")}
    end
  end

  @impl true
  def handle_event(target, value, socket), do: handle_event_switch(target, value, socket)

  defp handle_event_switch(target, params, socket) do
    case target do
      "submit" ->
        {
          :noreply,
          assign(socket, :info_modal, true)
          |> assign(:info_message, "Submit Role for Approval?")
          |> assign(:info_modal_param, Map.merge(params, %{"action" => "submit"}))
          |> assign(:info_wording, "Submit")
        }

      "approve" ->
        {
          :noreply,
          assign(socket, :info_modal, true)
          |> assign(:info_message, "Are you sure you want to Approve User Role?")
          |> assign(:info_modal_param, Map.merge(params, %{"action" => "approve"}))
          |> assign(:info_wording, "Approve")
        }

      "activate" ->
        {
          :noreply,
          assign(socket, :info_modal, true)
          |> assign(:info_message, "Are you sure you want to Activate User Role?")
          |> assign(:info_modal_param, Map.merge(params, %{"action" => "activate"}))
          |> assign(:info_wording, "Activate")
        }

      "deactivate" ->
        {
          :noreply,
          assign(socket, :info_modal, true)
          |> assign(:info_message, "Are you sure you want to deactivate the user role ?")
          |> assign(:info_modal_param, Map.merge(params, %{"action" => "deactivate"}))
          |> assign(:info_wording, "Deactivate")
        }

      "open_modal" ->
        open_modal(socket)

      "filter" ->
        list_roles(socket, params)

      "reload" ->
        {:noreply, push_redirect(socket, to: ~p"/Admin/roles")}
    end
  end

  defp open_modal(socket) do
    {:noreply, assign(socket, show_modal: true, page: "Filter Roles")}
  end

  defp list_roles(socket, params) do
    data = Roles.user_roles(Control.create_table_params(socket, params))

    {
      :noreply,
      assign(socket, :data, data)
      |> assign(data_loader: false)
      |> assign(show_modal: false)
      |> assign(params: params)
    }
  end

  defp handle_submit(%{assigns: assigns} = socket, %{"id" => id} = params) do
    Cache.put(assigns, :assigns)
    role = Roles.get_user_role_by_id(id)

    action = params["action"]
    params = %{status: switch_status(params["action"]), updated_by: socket.assigns.user.id}

    Ecto.Multi.new()
    |> Ecto.Multi.update(:role, UserRole.changeset(role, params))
    |> Ecto.Multi.merge(fn %{role: role} ->
      Logs.log_session(
        socket,
        "Updated Role [#{role.name}]",
        "UPDATE",
        role,
        "Role Management"
      )
    end)
    |> Repo.transaction()
    |> case do
      {:ok, _multi} ->
        ErrorHelper.get_results(socket, {:ok, switch_message(action)})

      {:error, _failed_operation, failed_value, _changes_so_far} ->
        reason = Utils.traverse_errors(failed_value.errors)
        ErrorHelper.get_results(socket, {:error, reason})
    end
  end

  defp switch_status(action) do
    case action do
      "approve" -> "ACTIVE"
      "reject" -> "REJECTED"
      "activate" -> "ACTIVE"
      "deactivate" -> "DEACTIVATED"
      "delete" -> "DELETED"
      _ -> "PENDING_APPROVAL"
    end
  end

  defp switch_message(action) do
    case action do
      "approve" -> " Approved Successfully."
      "reject" -> " Rejected Successfully."
      "activate" -> " Activated Successfully."
      "deactivate" -> " Deactivated Successfully."
      "delete" -> " deleted Successfully."
      _ -> "updated Successfully."
    end
  end
end
