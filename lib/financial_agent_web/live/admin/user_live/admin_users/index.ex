defmodule FinancialAgentWeb.Admin.UserLive.Index do
  use FinancialAgentWeb, :live_view

  alias FinancialAgent.Repo
  alias FinancialAgent.Roles
  alias FinancialAgent.Accounts
  alias FinancialAgent.Accounts.User
  alias FinancialAgent.Workers.Util.Utils
  alias FinancialAgent.Workers.Util.Helpers
  alias FinancialAgent.Workers.Helpers.UserLog
  alias FinancialAgentWeb.Helps.ErrorHelper
  alias FinancialAgentWeb.Helps.PaginationControl, as: Control

  alias FinancialAgentWeb.NotificationLive.{
    ErrorModalLive,
    InfoModalLive,
    SuccessModalLive
  }

  @impl true
  def mount(_params, _session, socket) do
      socket =
        assign(socket, :data_loader, true)
        |> assign(:data, [])
        |> assign(:info_modal, false)
        |> assign(error_modal: false)
        |> assign(error_message: "")
        |> assign(success_modal: false)
        |> assign(show_modal: false)
        |> assign(roles: Roles.list_user_roles())
        |> Control.order_by_composer()
        |> Control.i_search_composer()
        |> assign(:user_type, "BACKOFFICE")

      {:ok, socket}
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
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "Add User")
    |> assign(:user, %User{})
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit User")
    |> assign(:user, Accounts.get_user!(id))
  end

  defp apply_action(socket, :view, %{"id" => id}) do
    socket
    |> assign(:page_title, "User Details")
    |> assign(:tbl_user, Accounts.get_user!(id))
  end

  @impl true
  def handle_info(data, socket), do: handle_info_switch(socket, data)

  defp handle_info_switch(socket, data) do
    case data do
      :list_users ->
        list_users(socket, %{"sort_direction" => "desc", "sort_field" => "id"})

      {:list_users, params} ->
        list_users(socket, params)

      {:handle_user, params} ->
        handle_user(socket, params)

      {:approve, params} ->
        if connected?(socket), do: send(self(), {:handle_user, params})
        {:noreply, assign(socket, :info_wording, "Processing")}

      {:delete, params} ->
        if connected?(socket), do: send(self(), {:handle_user, params})
        {:noreply, assign(socket, :info_wording, "Processing")}

      {:reject, params} ->
        if connected?(socket), do: send(self(), {:handle_user, params})
        {:noreply, assign(socket, :info_wording, "Processing")}

      {:deactivate, params} ->
        if connected?(socket), do: send(self(), {:handle_user, params})
        {:noreply, assign(socket, :info_wording, "Processing")}

      {:activate, params} ->
        if connected?(socket), do: send(self(), {:handle_user, params})
        {:noreply, assign(socket, :info_wording, "Processing")}

      {:block, params} ->
        if connected?(socket), do: send(self(), {:handle_user, params})
        {:noreply, assign(socket, :info_wording, "Processing")}

      {:unblock, params} ->
        if connected?(socket), do: send(self(), {:handle_user, params})
        {:noreply, assign(socket, :info_wording, "Processing")}

      {InfoModalLive, _, %{action: action, param: params}} ->
        if action == "process" do
          case params["action"] do
            "approve" ->
              if connected?(socket), do: send(self(), {:approve, params})
              {:noreply, assign(socket, :info_wording, "Processing")}

            "reject" ->
              if connected?(socket), do: send(self(), {:reject, params})
              {:noreply, assign(socket, :info_wording, "Processing")}

            "delete" ->
              if connected?(socket), do: send(self(), {:delete, params})
              {:noreply, assign(socket, :info_wording, "Processing")}

            "activate" ->
              if connected?(socket), do: send(self(), {:activate, params})
              {:noreply, assign(socket, :info_wording, "Processing")}

            "deactivate" ->
              if connected?(socket), do: send(self(), {:deactivate, params})
              {:noreply, assign(socket, :info_wording, "Processing")}

            "block" ->
              if connected?(socket), do: send(self(), {:block, params})
              {:noreply, assign(socket, :info_wording, "Processing")}

            "unblock" ->
              if connected?(socket), do: send(self(), {:unblock, params})
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
        {:noreply, push_redirect(socket, to: ~p"/Admin/admin/users/management")}

      {ErrorModalLive, :button_clicked, _} ->
        {:noreply, push_redirect(socket, to: ~p"/Admin/admin/users/management")}
    end
  end

  @impl true
  def handle_event(target, value, socket), do: handle_event_switch(target, value, socket)

  defp handle_event_switch(target, params, socket) do
    case target do
      "iSearch" ->
        list_users(socket, params)

      "approve" ->
        {
          :noreply,
          assign(socket, :info_modal, true)
          |> assign(:info_message, "Are you sure you want to approve user?")
          |> assign(:info_modal_param, Map.merge(params, %{"action" => "approve"}))
          |> assign(:info_wording, "Approve")
        }

      "reject" ->
        {
          :noreply,
          assign(socket, :info_modal, true)
          |> assign(:info_message, "Are you sure you want to reject user?")
          |> assign(:info_modal_param, Map.merge(params, %{"action" => "reject"}))
          |> assign(:info_wording, "Reject")
        }

      "delete" ->
        {
          :noreply,
          assign(socket, :info_modal, true)
          |> assign(:info_message, "Are you sure you want to delete user?")
          |> assign(:info_modal_param, Map.merge(params, %{"action" => "delete"}))
          |> assign(:info_wording, "Delete")
        }

      "deactivate" ->
        {
          :noreply,
          assign(socket, :info_modal, true)
          |> assign(:info_message, "Are you sure you want to deactivate user?")
          |> assign(:info_modal_param, Map.merge(params, %{"action" => "deactivate"}))
          |> assign(:info_wording, "Deactivate")
        }

      "activate" ->
        {
          :noreply,
          assign(socket, :info_modal, true)
          |> assign(:info_message, "Are you sure you want to activate user?")
          |> assign(:info_modal_param, Map.merge(params, %{"action" => "activate"}))
          |> assign(:info_wording, "Activate")
        }

      "block" ->
        {
          :noreply,
          assign(socket, :info_modal, true)
          |> assign(:info_message, "Are you sure you want to block user?")
          |> assign(:info_modal_param, Map.merge(params, %{"action" => "block"}))
          |> assign(:info_wording, "Block")
        }

      "unblock" ->
        {
          :noreply,
          assign(socket, :info_modal, true)
          |> assign(:info_message, "Are you sure you want to unblock user?")
          |> assign(:info_modal_param, Map.merge(params, %{"action" => "unblock"}))
          |> assign(:info_wording, "Unblock")
        }

      "open_modal" ->
        open_modal(socket)

      "filter" ->
        list_users(socket, params)

      "reload" ->
        {:noreply, push_redirect(socket, to: ~p"/Admin/admin/users/management")}
    end
  end

  defp open_modal(socket) do
    {:noreply, assign(socket, show_modal: true, page: "Filter Users")}
  end

  defp list_users(%{assigns: assigns} = socket, params) do
    data =
      Accounts.list_system_users(Control.create_table_params(socket, params), assigns.user_type)

    {
      :noreply,
      assign(socket, :data, data)
      |> assign(data_loader: false)
      |> assign(show_modal: false)
      |> assign(params: params)
    }
  end

  defp handle_user(%{assigns: assigns} = socket, params) do
    user = Accounts.get_user!(params["id"])
    pwd = Utils.random_string(6)
    action = params["action"]
    user_params = switch_params(assigns, params, pwd)

    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, User.registration_changeset(user, user_params))
    |> Ecto.Multi.merge(fn %{user: user} -> Helpers.log_user_sms(user, pwd) end)
    |> Ecto.Multi.run(:logs, fn _repo, %{user: user} ->
      activity = "Updated an admin user name: #{user.first_name <> " " <> user.last_name} with id: #{user.id}"
      UserLog.log_user_log(activity, user)
    end)
    |> Repo.transaction()
    |> case do
      {:ok, _} ->
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
      "block" -> "ACTIVE"
      "unblock" -> "ACTIVE"
      "activate" -> "ACTIVE"
      "deactivate" -> "DEACTIVATED"
      "delete" -> "DELETED"
      _ -> "PENDING_APPROVAL"
    end
  end

  def switch_params(assigns, params, pwd) do
    case params["action"] do
      "block" ->
        %{
          updated_by: assigns.user.id,
          status: switch_status(params["action"]),
          password: pwd,
          blocked: true
        }

      "unblock" ->
        %{
          updated_by: assigns.user.id,
          status: switch_status(params["action"]),
          password: pwd,
          blocked: false
        }

      _ ->
        %{updated_by: assigns.user.id, status: switch_status(params["action"]), password: pwd}
    end
  end

  defp switch_message(action) do
    case action do
      "approve" -> "User Approved Successfully."
      "reject" -> " User Rejected Successfully."
      "activate" -> " User Activated Successfully."
      "deactivate" -> " User Deactivated Successfully."
      "delete" -> " User Deleted Successfully."
      "block" -> " User Blocked Successfully."
      "unblock" -> " User Unblocked Successfully."
      _ -> " Updated Successfully."
    end
  end
end
