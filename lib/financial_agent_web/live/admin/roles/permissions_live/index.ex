defmodule FinancialAgentWeb.PermissionsLive.Index do
  use FinancialAgentWeb, :live_view
  on_mount FinancialAgentWeb.UserLiveAuth

  alias FinancialAgent.Repo
  alias FinancialAgent.Roles
  alias FinancialAgent.Roles.Permissions
  alias FinancialAgent.Workers.Util.Utils
  alias FinancialAgent.Workers.Util.Cache
  alias FinancialAgentWeb.Helps.ErrorHelper
  alias FinancialAgentWeb.Helps.PaginationControl, as: Control
  alias FinancialAgentWeb.Components.Custom.Table

  alias FinancialAgentWeb.NotificationLive.{
    ErrorModalLive,
    InfoModalLive,
    SuccessModalLive
  }

  @changeset Roles.change_permissions(%Permissions{})

  @impl true
  def mount(params, _session, socket) do


      socket =
        assign(socket, :changeset, @changeset)
        |> assign(:data, [])
        |> assign(:data_loader, true)
        |> assign(:info_modal, false)
        |> assign(error_modal: false)
        |> assign(error_message: "")
        |> assign(success_modal: false)
        |> assign(show_modal: false)
        |> assign(:role, params["role"])
        |> Control.order_by_composer()
        |> Control.i_search_composer()

      {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    if connected?(socket), do: send(self(), {:list_permissions, params})

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
    Cache.put(socket.assigns, :assigns)

    socket
    |> assign(:page_title, "Add Permissions")
    |> assign(:permission, %Permissions{})
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    Cache.put(socket.assigns, :assigns)

    socket
    |> assign(:page_title, "Edit Permission")
    |> assign(:permission, Roles.get_permissions!(id))
  end

  @impl true
  def handle_info(data, socket), do: handle_info_switch(socket, data)

  defp handle_info_switch(socket, data) do
    case data do
      :list_permissions ->
        list_permissions(socket, %{"sort_direction" => "desc", "sort_field" => "id"})

      {:list_permissions, params} ->
        list_permissions(socket, params)

      {:handle_permission, params} ->
        handle_permission(socket, params)

      {:approve, params} ->
        if connected?(socket), do: send(self(), {:handle_permission, params})
        {:noreply, assign(socket, :info_wording, "Processing")}

      {:delete, params} ->
        if connected?(socket), do: send(self(), {:handle_permission, params})
        {:noreply, assign(socket, :info_wording, "Processing")}

      {:reject, params} ->
        if connected?(socket), do: send(self(), {:handle_permission, params})
        {:noreply, assign(socket, :info_wording, "Processing")}

      {:deactivate, params} ->
        if connected?(socket), do: send(self(), {:handle_permission, params})
        {:noreply, assign(socket, :info_wording, "Processing")}

      {:activate, params} ->
        if connected?(socket), do: send(self(), {:handle_permission, params})
        {:noreply, assign(socket, :info_wording, "Processing")}

      {InfoModalLive, _, %{action: action, param: params}} ->
        if action == "process" do
          case params["action"] do
            "approve" ->
              if connected?(socket), do: send(self(), {:approve, params})
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
        {:noreply, push_redirect(socket, to: ~p"/Admin/permissions")}

      {ErrorModalLive, :button_clicked, _} ->
        {:noreply, push_redirect(socket, to: ~p"/Admin/permissions")}
    end
  end

  @impl true
  def handle_event(target, value, socket), do: handle_event_switch(target, value, socket)

  defp handle_event_switch(target, params, socket) do
    case target do
      "iSearch" ->
        list_permissions(socket, params)

      "approve" ->
        {
          :noreply,
          assign(socket, :info_modal, true)
          |> assign(:info_message, "Are you sure you want to approve Permission?")
          |> assign(:info_modal_param, Map.merge(params, %{"action" => "approve"}))
          |> assign(:info_wording, "Approve")
        }

      "delete" ->
        {
          :noreply,
          assign(socket, :info_modal, true)
          |> assign(:info_message, "Are you sure you want to delete Permission?")
          |> assign(:info_modal_param, Map.merge(params, %{"action" => "delete"}))
          |> assign(:info_wording, "Delete")
        }

      "activate" ->
        {
          :noreply,
          assign(socket, :info_modal, true)
          |> assign(:info_message, "Are you sure you want to activate Permission?")
          |> assign(:info_modal_param, Map.merge(params, %{"action" => "activate"}))
          |> assign(:info_wording, "Activate")
        }

      "deactivate" ->
        {
          :noreply,
          assign(socket, :info_modal, true)
          |> assign(:info_message, "Are you sure you want to deactivate Permission?")
          |> assign(:info_modal_param, Map.merge(params, %{"action" => "deactivate"}))
          |> assign(:info_wording, "Deactivate")
        }

      "open_modal" ->
        open_modal(socket)

      "filter" ->
        list_permissions(socket, params)

      "reload" ->
        {:noreply, push_redirect(socket, to: ~p"/Admin/permissions")}
    end
  end

  defp open_modal(socket) do
    {:noreply, assign(socket, show_modal: true, page: "Filter Permissions")}
  end

  defp list_permissions(socket, params) do
    data = Roles.get_permissions(Control.create_table_params(socket, params))

    {
      :noreply,
      assign(socket, :data, data)
      |> assign(data_loader: false)
      |> assign(show_modal: false)
      |> assign(params: params)
    }
  end

  defp handle_permission(%{assigns: assigns} = socket, %{"id" => id} = params) do
    permission = Roles.get_permissions!(id)
    action = params["action"]
    params = %{updated_by: assigns.user.id, status: switch_status(params["action"])}

    Ecto.Multi.new()
    |> Ecto.Multi.update(:permission, Permissions.changeset(permission, params))
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
      "approve" -> " Approved Successfully."
      "reject" -> " Rejected Successfully."
      "activate" -> " Activated Successfully."
      "deactivate" -> " Deactivated Successfully."
      "delete" -> " Deleted Successfully."
      _ -> " Updated Successfully."
    end
  end
end
