defmodule FinincialAgentWeb.SmsConfigurationsLive.FormComponent do
  @moduledoc false
  use FinincialAgentWeb, :live_component

  alias FinincialAgent.Settings
  alias FinincialAgent.Settings.SmsConfigs

  @impl true
  def update(%{sms_config: sms_config} = assigns, socket) do
    changeset = SmsConfigs.changeset(sms_config, %{})

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  @impl true
  def handle_event("validate", %{"sms_configs" => sms_config_params}, socket) do
    changeset =
      socket.assigns.sms_config
      |> SmsConfigs.changeset(sms_config_params)

    # |> Map.punt(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("save", %{"sms_configs" => sms_config_params}, socket) do
    save_sms_config(socket, socket.assigns.action, sms_config_params)
  end

  defp save_sms_config(socket, :edit, sms_config_params) do
    case Settings.update_config(socket.assigns.sms_config, sms_config_params) do
      {:ok, _settings} ->
        {:noreply,
         socket
         |> put_flash(:info, "Sms Configuration updated successfully")
         |> push_redirect(to: "/Admin/sms/configurations")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  defp save_sms_config(socket, :new, sms_config_params) do
    updated_params = Map.put(sms_config_params, "status", "PENDING_APPROVAL")

    case Settings.create_config(updated_params) do
      {:ok, _sms_config} ->
        {:noreply,
         socket
         |> put_flash(:info, "Sms Configuration Added successfully")
         |> push_redirect(to: "/Admin/sms/configurations")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end
end
