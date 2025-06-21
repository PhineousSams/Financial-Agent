defmodule FinancialAgentWeb.PermissionGroupsLive.Index do
  use FinancialAgentWeb, :live_view

  alias FinancialAgent.Repo
  alias FinancialAgentWeb.Helps.ErrorHelper
  alias FinancialAgent.Workers.Util.Utils
  alias FinancialAgentWeb.Helps.PaginationControl, as: Control

  alias FinancialAgent.Roles
  alias FinancialAgent.Roles.PermissionGroups

  alias FinancialAgentWeb.NotificationLive.{
    ErrorModalLive,
    InfoModalLive,
    SuccessModalLive
  }

  @impl true
  def mount(_params, _session, %{assigns: _assigns} = socket) do
    socket =
      assign(socket, :data_loader, true)
      |> assign(:permission_groups, [])
      |> assign(:info_modal, false)
      |> assign(error_modal: false)
      |> assign(error_message: "")
      |> assign(success_modal: false)
      |> assign(show_modal: false)
      |> Control.order_by_composer()
      |> Control.i_search_composer()

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    if connected?(socket), do: send(self(), {:list_permission_group, params})

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
    |> assign(:page_title, "Add Group")
    |> assign(:permission_group, %PermissionGroups{})
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Group")
    |> assign(:permission_group, Roles.get_permission_groups!(id))
  end

  defp apply_action(socket, :view, %{"id" => id}) do
    socket
    |> assign(:page_title, "Group Details")
    |> assign(:group, Roles.get_permission_groups!(id))
  end

  @impl true
  def handle_info(data, socket), do: handle_info_switch(socket, data)

  defp handle_info_switch(socket, data) do
    case data do
      :list_permission_group ->
        list_groups(socket, %{"sort_direction" => "desc", "sort_field" => "id"})

      {:list_permission_group, params} ->
        list_groups(socket, params)

      {:handle_group, params} ->
        handle_group(socket, params)

      {:approve, params} ->
        if connected?(socket), do: send(self(), {:handle_group, params})
        {:noreply, assign(socket, :info_wording, "Processing")}

      {:delete, params} ->
        if connected?(socket), do: send(self(), {:handle_group, params})
        {:noreply, assign(socket, :info_wording, "Processing")}

      {:reject, params} ->
        if connected?(socket), do: send(self(), {:handle_group, params})
        {:noreply, assign(socket, :info_wording, "Processing")}

      {:deactivate, params} ->
        if connected?(socket), do: send(self(), {:handle_group, params})
        {:noreply, assign(socket, :info_wording, "Processing")}

      {:activate, params} ->
        if connected?(socket), do: send(self(), {:handle_group, params})
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
        {:noreply, push_redirect(socket, to: ~p"/Admin/permission_groups")}

      {ErrorModalLive, :button_clicked, _} ->
        {:noreply, push_redirect(socket, to: ~p"/Admin/permission_groups")}
    end
  end

  @impl true
  def handle_event(target, value, socket), do: handle_event_switch(target, value, socket)

  defp handle_event_switch(target, params, socket) do
    case target do
      "iSearch" ->
        list_groups(socket, params)

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

      "open_modal" ->
        open_modal(socket)

      "filter" ->
        list_groups(socket, params)

      "reload" ->
        {:noreply, push_redirect(socket, to: ~p"/Admin/permission_groups")}
    end
  end

  defp open_modal(socket) do
    {:noreply, assign(socket, show_modal: true, page: "Filter Users")}
  end

  defp list_groups(%{assigns: __assigns} = socket, params) do
    data = Roles.get_permissions_group(Control.create_table_params(socket, params))

    {
      :noreply,
      assign(socket, :permission_groups, data)
      |> assign(data_loader: false)
      |> assign(show_modal: false)
      |> assign(params: params)
    }
  end

  defp handle_group(%{assigns: assigns} = socket, params) do
    group = Roles.get_permission_groups!(params["id"])
    action = params["action"]

    params =
      Map.put_new(params, "status", switch_status(action))
      |> Map.put_new("updated_by", assigns.current_user.id)

    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, PermissionGroups.changeset(group, params))
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
      "activate" -> "ACTIVE"
      "deactivate" -> "DEACTIVATED"
      "delete" -> "DELETED"
      _ -> "PENDING_APPROVAL"
    end
  end

  defp switch_message(action) do
    case action do
      "approve" -> "Group Approved Successfully."
      "reject" -> " Group Rejected Successfully."
      "activate" -> " Group Activated Successfully."
      "deactivate" -> " Group Deactivated Successfully."
      "delete" -> " Group Deleted Successfully."
      _ -> " Updated Successfully."
    end
  end
end
