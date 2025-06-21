defmodule FinincialAgentWeb.ConfigsLive.FormComponent do
  @moduledoc false
  use FinincialAgentWeb, :live_component

  alias FinincialAgent.Settings

  @impl true
  def update(%{settings: settings} = assigns, socket) do
    changeset = Settings.change_settings(settings)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"config_settings" => settings_params}, socket) do
    changeset =
      socket.assigns.settings
      |> Settings.change_settings(settings_params)

    # |> Map.punt(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  def handle_event("save", %{"config_settings" => settings_params}, socket) do
    save_settings(socket, socket.assigns.action, settings_params)
  end

  defp save_settings(socket, :edit, settings_params) do
    case Settings.update_settings(socket.assigns.settings, settings_params) do
      {:ok, _settings} ->
        {:noreply,
         socket
         |> put_flash(:info, "Settings updated successfully")
         |> push_redirect(to: "/Admin/Configs/management")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  defp save_settings(socket, :new, settings_params) do
    update_params =
      Map.update(
        settings_params,
        "value_type",
        settings_params["value_type"],
        &String.downcase(&1)
      )

    case Settings.create_settings(update_params) do
      {:ok, _settings} ->
        {:noreply,
         socket
         |> put_flash(:info, "System Settings Added successfully")
         |> push_redirect(to: "/Admin/Configs/management")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end
end
