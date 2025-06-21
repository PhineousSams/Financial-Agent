defmodule FinancialAgentWeb.ApiIntegratorsLive.Index do
  use FinancialAgentWeb, :live_view

  alias FinancialAgent.Repo
  alias FinancialAgent.Logs
  alias FinancialAgent.Settings
  alias FinancialAgent.Settings.ApiIntegrator
  alias FinancialAgent.Workers.Util.Utils
  alias FinancialAgent.Workers.Helpers.UserLog
  alias FinancialAgentWeb.Components.Custom.Table
  alias FinancialAgentWeb.Helps.PaginationControl, as: Control

  alias FinancialAgentWeb.NotificationLive.{
    ErrorModalLive,
    InfoModalLive,
    SuccessModalLive
  }

  @url "/Admin/configurations/api_integrators"

  @impl true
  def mount(params, session, %{assigns: assigns} = socket) do
    {:ok,
      socket
      |> assign(:data, [])
      |> assign(:data_loader, true)
      |> assign(:show_password_modal, false)
      |> assign(:generated_password, nil)
      |> assign(:error, "")
      |> assign(:error_modal, false)
      |> assign(:info_modal, false)
      |> assign(:success_modal, false)
      |> Control.order_by_composer()
      |> Control.i_search_composer()
    }
  end

  @impl true
  def handle_params(params, _url, socket) do
    if connected?(socket), do: send(self(), {:api_integrators, params})

    {
      :noreply,
      socket
      |> assign(:params, params)
      |> apply_action(socket.assigns.live_action, params)
    }
  end

  @impl true
  def handle_info(data, socket), do: handle_info_switch(socket, data)

  defp handle_info_switch(socket, data) do
    case data do
      :api_integrators ->
        get_integrators(socket, %{"sort_direction" => "desc", "sort_field" => "id"})

      {:api_integrators, params} ->
        get_integrators(socket, params)

      {:handle_integrator, params} ->
        handle_integrator(socket, params)

      {:approve, params} ->
        if connected?(socket), do: send(self(), {:handle_integrator, params})
        {:noreply, assign(socket, :info_wording, "Processing")}

      {:delete, params} ->
        if connected?(socket), do: send(self(), {:handle_integrator, params})
        {:noreply, assign(socket, :info_wording, "Processing")}

      {:reject, params} ->
        if connected?(socket), do: send(self(), {:handle_integrator, params})
        {:noreply, assign(socket, :info_wording, "Processing")}

      {:deactivate, params} ->
        if connected?(socket), do: send(self(), {:handle_integrator, params})
        {:noreply, assign(socket, :info_wording, "Processing")}

      {:activate, params} ->
        if connected?(socket), do: send(self(), {:handle_integrator, params})
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
        {:noreply, push_redirect(socket, to: "/Admin/configurations/api_integrators")}

      {ErrorModalLive, :button_clicked, _} ->
        {:noreply, push_redirect(socket, to: "/Admin/configurations/api_integrators")}
    end
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit API Integrator")
    |> assign(:integrator, Settings.get_integrator!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New API Integrator")
    |> assign(:integrator, %ApiIntegrator{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "API Integrators")
    |> assign(:integrator, nil)
  end

  @impl true
  def handle_event(target, value, socket), do: handle_event_switch(target, value, socket)

  defp handle_event_switch(target, params, socket) do
    case target do
      "iSearch" -> get_integrators(socket, params)
      "generate_password" -> generate_password(params, socket)
      "close_password_modal" -> {:noreply, assign(socket, :show_password_modal, false)}
      "reset_attempts" -> reset_attempts(params, socket)
      "reload" -> get_integrators(socket, %{"sort_direction" => "desc", "sort_field" => "id"})

      "approve" ->
        {
          :noreply,
          assign(socket, :info_modal, true)
          |> assign(:info_message, "Are you sure you want to approve this API integrator?")
          |> assign(:info_modal_param, Map.merge(params, %{"action" => "approve"}))
          |> assign(:info_wording, "Approve")
        }

      "reject" ->
        {
          :noreply,
          assign(socket, :info_modal, true)
          |> assign(:info_message, "Are you sure you want to reject this API integrator?")
          |> assign(:info_modal_param, Map.merge(params, %{"action" => "reject"}))
          |> assign(:info_wording, "Reject")
        }

      "delete" ->
        {
          :noreply,
          assign(socket, :info_modal, true)
          |> assign(:info_message, "Are you sure you want to delete this API integrator?")
          |> assign(:info_modal_param, Map.merge(params, %{"action" => "delete"}))
          |> assign(:info_wording, "Delete")
        }

      "deactivate" ->
        {
          :noreply,
          assign(socket, :info_modal, true)
          |> assign(:info_message, "Are you sure you want to deactivate this API integrator?")
          |> assign(:info_modal_param, Map.merge(params, %{"action" => "deactivate"}))
          |> assign(:info_wording, "Deactivate")
        }

      "activate" ->
        {
          :noreply,
          assign(socket, :info_modal, true)
          |> assign(:info_message, "Are you sure you want to activate this API integrator?")
          |> assign(:info_modal_param, Map.merge(params, %{"action" => "activate"}))
          |> assign(:info_wording, "Activate")
        }
    end
  end

  defp handle_integrator(%{assigns: assigns} = socket, params) do
    integrator = Settings.get_integrator!(params["id"])

    integrator_params =
      Map.merge(Utils.to_atomic_map(params), %{
        status: switch_status(params["action"]),
        checker_id: socket.assigns.user.id
      })

    Ecto.Multi.new()
    |> Ecto.Multi.update(:integrator, ApiIntegrator.changeset(integrator, integrator_params))
    |> Ecto.Multi.run(:logs, fn _repo, %{integrator: integrator} ->
      activity = "Updated API integrator with id: #{integrator.id}, action: #{params["action"]}"
      UserLog.log_user_log(activity, socket.assigns.user)
    end)
    |> Repo.transaction()
    |> case do
      {:ok, _} ->
        {
          :noreply,
          socket
          |> assign(:success_modal, true)
          |> assign(:success_message, switch_message(params["action"]))
        }

      {:error, _failed_operation, failed_value, _changes_so_far} ->
        reason = Utils.traverse_errors(failed_value.errors)
        {
          :noreply,
          socket
          |> assign(:error_modal, true)
          |> assign(:error_message, reason)
        }
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
      "approve" -> "API integrator approval successfully."
      "reject" -> "API integrator rejected."
      "activate" -> "API integrator activation successfully."
      "deactivate" -> "API integrator deactivated."
      "delete" -> "API integrator deleted."
      _ -> "API integrator updated successfully."
    end
  end

  def delete_integrator(%{"id" => id}, socket) do
    integrator = Settings.get_integrator!(id)

    Ecto.Multi.new()
    |> Ecto.Multi.delete(:integrator, integrator)
    |> Ecto.Multi.run(:logs, fn _repo, %{integrator: integrator} ->
      activity = "Deleted API integrator with id: #{integrator.id}"
      UserLog.log_user_log(activity, socket.assigns.user)
    end)
    |> Repo.transaction()
    |> case do
      {:ok, _} ->
        {
          :noreply,
          socket
          |> assign(:success_modal, true)
          |> assign(:success_message, "API integrator deleted successfully")
        }

      {:error, _failed_operation, failed_value, _changes_so_far} ->
        reason = Utils.traverse_errors(failed_value.errors)
        {
          :noreply,
          socket
          |> assign(:error_modal, true)
          |> assign(:error_message, reason)
        }
    end
  end

  def generate_password(%{"id" => id}, socket) do
    integrator = Settings.get_integrator!(id)

    case Settings.generate_new_password(integrator) do
      {:ok, password, _updated_integrator} ->
        {:noreply,
         socket
         |> assign(:show_password_modal, true)
         |> assign(:generated_password, password)}

      {:error, _changeset} ->
        {:noreply,
         socket
         |> put_flash(:error, "Failed to generate new password")
         |> assign(:show_password_modal, false)}
    end
  end

  def reset_attempts(%{"id" => id}, socket) do
    integrator = Settings.get_integrator!(id)
    Settings.reset_attempt_count(integrator)

    {:noreply,
     socket
     |> put_flash(:info, "Attempt count reset successfully")
     |> push_navigate(to: ~p"/Admin/configurations/api_integrators")}
  end

  defp list_integrators do
    Settings.list_integrators()
  end

  defp get_integrators(%{assigns: _assigns} = socket, params) do
    data = Settings.get_bill_integrators(Control.create_table_params(socket, params))

    {
      :noreply,
      assign(socket, :data, data)
      |> assign(data_loader: false)
      |> assign(params: params)
    }
  end
end
