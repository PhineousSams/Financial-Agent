defmodule FinincialAgentWeb.UserLive.Blocked do
  use FinincialAgentWeb, :live_view

  alias FinincialAgent.Repo
  alias FinincialAgent.Accounts
  alias FinincialAgent.Roles
  alias FinincialAgent.Accounts.User
  alias FinincialAgent.Workers.Util.Utils
  alias FinincialAgent.Workers.Util.Helpers
  alias FinincialAgent.Workers.Helpers.UserLog
  alias FinincialAgentWeb.Helps.ErrorHelper
  alias FinincialAgentWeb.Helps.PaginationControl, as: Control

  alias FinincialAgentWeb.NotificationLive.{
    ErrorModalLive,
    InfoModalLive,
    SuccessModalLive
  }

  @impl true
  def mount(_params, _session, %{assigns: _assigns} = socket) do
    socket =
      assign(socket, :data_loader, true)
      |> assign(:data, [])
      |> assign(:info_modal, false)
      |> assign(error_modal: false)
      |> assign(error_message: "")
      |> assign(success_modal: false)
      |> assign(show_modal: false)
      |> Control.order_by_composer()
      |> assign(roles: Roles.list_user_roles())
      |> Control.i_search_composer()
      |> assign(:user_type, "BACKOFFICE")

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    if connected?(socket), do: send(self(), {:list_blocked_users, params})

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

  @impl true
  def handle_info(data, socket), do: handle_info_switch(socket, data)

  defp handle_info_switch(socket, data) do
    case data do
      :list_blocked_users ->
        list_blocked_users(socket, %{"sort_direction" => "desc", "sort_field" => "id"})

      {:list_blocked_users, params} ->
        list_blocked_users(socket, params)

      {:handle_user, params} ->
        handle_user(socket, params)

      {:unblock, params} ->
        if connected?(socket), do: send(self(), {:handle_user, params})
        {:noreply, assign(socket, :info_wording, "Processing")}

      {InfoModalLive, _, %{action: action, param: params}} ->
        if action == "process" do
          case params["action"] do
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
        {:noreply, push_redirect(socket, to: ~p"/Admin/admin/users/blocked")}

      {ErrorModalLive, :button_clicked, _} ->
        {:noreply, push_redirect(socket, to: ~p"/Admin/admin/users/blocked")}
    end
  end

  @impl true
  def handle_event(target, value, socket), do: handle_event_switch(target, value, socket)

  defp handle_event_switch(target, params, socket) do
    case target do
      "iSearch" ->
        list_blocked_users(socket, params)

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
        list_blocked_users(socket, params)

      "reload" ->
        {:noreply, push_redirect(socket, to: ~p"/Admin/admin/users/blocked")}
    end
  end

  defp open_modal(socket) do
    {:noreply, assign(socket, show_modal: true, page: "Filter Blocked Users")}
  end

  defp list_blocked_users(%{assigns: assigns} = socket, params) do
    data =
      Accounts.get_blocked_users(Control.create_table_params(socket, params), assigns.user_type)

    {
      :noreply,
      assign(socket, :data, data)
      |> assign(data_loader: false)
      |> assign(show_modal: false)
      |> assign(params: params)
    }
  end

  defp handle_user(%{assigns: assigns} = socket, %{"id" => id}) do
    user = Accounts.get_user!(id)
    pwd = Utils.random_string(6)

    params = %{
      updated_by: assigns.user.id,
      auto_pwd: true,
      password: pwd,
      blocked: false,
      failed_attempts: 0
    }

    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, User.changeset(user, params))
    |> Ecto.Multi.merge(fn %{user: user} -> Helpers.log_user_sms(user, pwd) end)
    |> Ecto.Multi.run(:logs, fn _repo, %{user: user} ->
      activity = "Updated a blocked user named: #{user.first_name <> " " <> user.last_name} with id: #{user.id}"
      UserLog.log_user_log(activity, user)
    end)
    |> Repo.transaction()
    |> case do
      {:ok, _multi} ->
        ErrorHelper.get_results(socket, {:ok, "User Unblocked Successfully."})

      {:error, _failed_operation, failed_value, _changes_so_far} ->
        reason = Utils.traverse_errors(failed_value.errors)
        ErrorHelper.get_results(socket, {:error, reason})
    end
  end
end
