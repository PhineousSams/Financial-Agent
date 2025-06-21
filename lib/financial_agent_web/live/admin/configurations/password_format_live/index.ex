defmodule FinincialToolWeb.PasswordFormatLive.Index do
  use FinincialToolWeb, :live_view

  alias FinincialTool.Repo
  alias FinincialTool.Configs
  alias FinincialTool.Workers.Util.Utils
  alias FinincialTool.Configs.PasswordConfig
  alias FinincialTool.Workers.Helpers.UserLog

  @impl true
  def mount(_params, _session, %{assigns: _assigns} = socket) do
    map = get_settings()

    socket =
      assign(socket, :my_action, map.action)
      |> assign(:configs, map.configs)
      |> assign(:form, to_form(Configs.change_password_config(map.configs)))

    {:ok, socket}
  end

  defp get_settings() do
    case Configs.get_pasword_configs() do
      nil -> %{configs: %PasswordConfig{}, action: :new}
      configs -> %{configs: configs, action: :edit}
    end
  end

  @impl true
  def handle_event(target, value, socket), do: handle_event_switch(target, value, socket)

  defp handle_event_switch(target, params, socket) do
    case target do
      "validate" -> validate(params, socket)
      "save" -> save_configs(socket, params)
    end
  end

  def validate(params, socket) do
    changeset =
      socket.assigns.configs
      |> Configs.change_password_config(params["password_config"])
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  defp save_configs(%{assigns: assigns} = socket, params) do
    params = Utils.to_atomic_map(params)

    handle_configs(socket, params, assigns.my_action)
    |> case do
      {:ok, message} ->
        socket =
          socket
          |> put_flash(:info, message)
          |> push_navigate(to: "/Admin/password_format")

        {:noreply, socket}

      {:error, reason} ->
        socket =
          socket
          |> put_flash(:error, reason)

        {:noreply, socket}
    end
  end

  defp handle_configs(%{assigns: assigns}, %{password_config: configs}, :new) do
    configs = Map.merge(configs, %{maker_id: assigns.user.id})

    Ecto.Multi.new()
    |> Ecto.Multi.insert(:config, PasswordConfig.changeset(%PasswordConfig{}, configs))
    |> Ecto.Multi.run(:logs, fn _repo, %{config: config} ->
      activity = "Created Password Configs with ID: #{config.id}"
      UserLog.log_user_log(activity, assigns.user)
    end)
    |> Repo.transaction()
    |> case do
      {:ok, _multi} ->
        {:ok, "Password Configurations Set successfully."}

      {:error, _failed_operation, failed_value, _changes_so_far} ->
        reason = Utils.traverse_errors(failed_value.errors)
        {:error, reason}
    end
  end

  defp handle_configs(%{assigns: assigns}, %{password_config: configs}, :edit) do
    configs = Map.merge(configs, %{updated_by: assigns.user.id})

    Ecto.Multi.new()
    |> Ecto.Multi.update(:config, PasswordConfig.changeset(assigns.configs, configs))
    |> Ecto.Multi.run(:logs, fn _repo, %{config: config} ->
      activity = "Updated Password Configs with ID: #{config.id}"
      UserLog.log_user_log(activity, assigns.user)
    end)
    |> Repo.transaction()
    |> case do
      {:ok, _multi} ->
        {:ok, "Password Configurations updated Successfully."}

      {:error, _failed_operation, failed_value, _changes_so_far} ->
        reason = Utils.traverse_errors(failed_value.errors)
        {:error, reason}
    end
  end
end
