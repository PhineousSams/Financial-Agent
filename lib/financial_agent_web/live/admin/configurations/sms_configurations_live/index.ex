defmodule FinancialAgentWeb.Admin.SmsConfigurationsLive.Index do
  use FinancialAgentWeb, :live_view


  alias FinancialAgent.Repo
  alias FinancialAgent.Logs
  alias FinancialAgent.Settings
  alias FinancialAgent.Settings.SmsConfigs
  alias FinancialAgent.Workers.Util.Utils
  alias FinancialAgentWeb.Helps.ErrorHelper
  alias FinancialAgent.Workers.Helpers.UserLog
  alias FinancialAgent.Workers.Helpers.PermissionsCheck
  alias FinancialAgentWeb.Helps.PaginationControl, as: Control

  alias FinancialAgentWeb.NotificationLive.{
    ErrorModalLive,
    InfoModalLive,
    SuccessModalLive
  }


  @impl true
  def mount(params, session, %{assigns: assigns} = socket) do
    if PermissionsCheck.page_access("access_sms_configurations", assigns.permits) do
      Task.start(fn ->
        Logs.system_log_session(
          session,
          "Access SMS Configurations Page",
          "Access",
          params,
          "Access SMS Configurations Page",
          assigns.user.id
        )
      end)

      socket =
        assign(socket, :data, [])
        |> assign(:data_loader, true)
        |> assign(:error, "")
        |> assign(:error_modal, false)
        |> assign(:info_modal, false)
        |> assign(:success_modal, false)
        |> Control.order_by_composer()
        |> Control.i_search_composer()

      {:ok, socket}
    else
      Task.start(fn ->
        Logs.system_log_session(
          session,
          "Access SMS Configurations Page Denied due to permissions access",
          "Access Denied",
          params,
          "Access SMS Configurations Page",
          assigns.current_user.id
        )
      end)

      {:ok,
      socket
      |> put_flash(:error, "Unauthorized action: You don't have permission to view this content!")
      |> push_redirect(to: ~p"/", replace: true)}
    end
  end

  @impl true
  def handle_params(params, _url, socket) do
    if connected?(socket), do: send(self(), {:list_configs, params})

    {
      :noreply,
      socket
      |> assign(:params, params)
      |> apply_action(socket.assigns.live_action, params)
    }
  end

  defp apply_action(socket, :index, _) do
    socket
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "Add SMS Configuration")
    |> assign(:sms_config, %SmsConfigs{})
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Settings")
    |> assign(:sms_config, Settings.get_sms_config!(id))
  end

  @impl true
  def handle_info(data, socket), do: handle_info_switch(socket, data)

  defp handle_info_switch(socket, data) do
    case data do
      :list_configs ->
        list_configs(socket, %{"sort_direction" => "desc", "sort_field" => "id"})

      {:list_configs, params} ->
        list_configs(socket, params)

      {:handle_config, params} ->
        handle_config(socket, params)

      {:approve, params} ->
        if connected?(socket), do: send(self(), {:handle_config, params})
        {:noreply, assign(socket, :info_wording, "Processing")}

      {:delete, params} ->
        if connected?(socket), do: send(self(), {:handle_config, params})
        {:noreply, assign(socket, :info_wording, "Processing")}

      {:reject, params} ->
        if connected?(socket), do: send(self(), {:handle_config, params})
        {:noreply, assign(socket, :info_wording, "Processing")}

      {:deactivate, params} ->
        if connected?(socket), do: send(self(), {:handle_config, params})
        {:noreply, assign(socket, :info_wording, "Processing")}

      {:activate, params} ->
        if connected?(socket), do: send(self(), {:handle_config, params})
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
        {:noreply, push_redirect(socket, to: "/Admin/sms/configurations")}

      {ErrorModalLive, :button_clicked, _} ->
        {:noreply, push_redirect(socket, to: "/Admin/sms/configurations")}
    end
  end

  defp list_configs(%{assigns: _assigns} = socket, params) do
    data = Settings.list_sms_settings(Control.create_table_params(socket, params))

    {
      :noreply,
      assign(socket, :data, data)
      |> assign(data_loader: false)
      |> assign(params: params)
    }
  end

  @impl true
  def handle_event(target, value, socket), do: handle_event_switch(target, value, socket)

  defp handle_event_switch(target, params, socket) do
    case target do
      "iSearch" ->
        list_configs(socket, params)

      "approve" ->
        {
          :noreply,
          assign(socket, :info_modal, true)
          |> assign(:info_message, "Are you sure you want to approve class?")
          |> assign(:info_modal_param, Map.merge(params, %{"action" => "approve"}))
          |> assign(:info_wording, "Approve")
        }

      "reject" ->
        {
          :noreply,
          assign(socket, :info_modal, true)
          |> assign(:info_message, "Are you sure you want to reject class?")
          |> assign(:info_modal_param, Map.merge(params, %{"action" => "reject"}))
          |> assign(:info_wording, "Reject")
        }

      "delete" ->
        {
          :noreply,
          assign(socket, :info_modal, true)
          |> assign(:info_message, "Are you sure you want to delete class?")
          |> assign(:info_modal_param, Map.merge(params, %{"action" => "delete"}))
          |> assign(:info_wording, "Delete")
        }

      "deactivate" ->
        {
          :noreply,
          assign(socket, :info_modal, true)
          |> assign(:info_message, "Are you sure you want to deactivate class?")
          |> assign(:info_modal_param, Map.merge(params, %{"action" => "deactivate"}))
          |> assign(:info_wording, "Deactivate")
        }

      "activate" ->
        {
          :noreply,
          assign(socket, :info_modal, true)
          |> assign(:info_message, "Are you sure you want to activate class?")
          |> assign(:info_modal_param, Map.merge(params, %{"action" => "activate"}))
          |> assign(:info_wording, "Activate")
        }
    end
  end

  defp handle_config(%{assigns: _assigns} = socket, params) do
    sms_config = Settings.get_sms_config!(params["id"])

    sms_config_params =
      Map.merge(Utils.to_atomic_map(params), %{
        status: switch_status(params["action"]),
        updated_by: socket.assigns.user.id
      })

    Ecto.Multi.new()
    |> Ecto.Multi.update(:sms_config, SmsConfigs.changeset(sms_config, sms_config_params))
    |> Ecto.Multi.run(:logs, fn _repo, %{sms_config: sms_config} ->
      activity = "Updated sms config with id: #{sms_config.id}"
      UserLog.log_user_log(activity, socket.assigns.user)
    end)
    |> Repo.transaction()
    |> case do
      {:ok, _} ->
        ErrorHelper.get_results(socket, {:ok, switch_message(params["action"])})

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
      "approve" -> "SMS configuration approval successfully."
      "reject" -> "SMS configuration rejected."
      "activate" -> "SMS configuration activation successfully."
      "deactivate" -> "SMS configuration deactivated."
      "delete" -> "SMS configuration deleted."
      _ -> "SMS configuration updated successfully."
    end
  end
end
