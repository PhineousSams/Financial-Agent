defmodule FinincialToolWeb.SessionLive.Reset do
  use FinincialToolWeb, :live_view

  alias FinincialTool.Repo
  alias FinincialTool.Configs
  alias FinincialTool.Accounts
  alias FinincialTool.Accounts.User
  alias FinincialTool.Workers.Util.Utils
  alias FinincialTool.Workers.Helpers.PwdValidator

  @impl true
  def mount(_params, _session, %{assigns: assigns} = socket) do
    user = %User{}
    changeset = Accounts.password_changeset(user)

    {:ok,
     socket
     |> assign(:info_modal, false)
     |> assign(error_modal: false)
     |> assign(:user, user)
     |> assign(:login_user, Accounts.get_user!(assigns.user.id))
     |> assign(:loader, false)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event(target, params, socket), do: handle_event_switch(target, params, socket)

  def handle_event_switch(target, params, %{assigns: assigns} = socket) do
    user = assigns.login_user

    params = Utils.to_atomic_map(params)

    case target do
      "validate" ->
        {:noreply, socket}

      "submit" ->
        socket =
          socket
           |> assign(:loader, true)
           |> assign(:login_user, user)
           |> assign(:user_params, params)

        Process.send_after(self(), :submit, 4000)

        {:noreply, socket}
    end
  end

  @impl true
  def handle_info(:submit, socket) do

      params = socket.assigns.user_params
      user = socket.assigns.login_user

        case Configs.get_pasword_configs() do
          nil ->
            resp(:error, "System Configurations not Set, Contact System Administrator", socket)

          configs ->
            with {:ok, _} <-
                   User.validate_passwords(
                     user,
                     params.user.current_password,
                     params.user.password,
                     params.user.confirm_password,
                     configs
                   ),
                 {:ok, _message} <- PwdValidator.check_pwd_size(params.user.password, configs),
                 {:ok, _message} <-
                   PwdValidator.custom_pwd_validation(:numeric, params.user.password, configs),
                 {:ok, _message} <-
                   PwdValidator.custom_pwd_validation(:special, params.user.password, configs),
                 {:ok, _message} <-
                   PwdValidator.custom_pwd_validation(:lowercase, params.user.password, configs),
                 {:ok, _message} <-
                   PwdValidator.custom_pwd_validation(:uppercase, params.user.password, configs),
                 {:ok, _message} <- PwdValidator.repetitive_characters(params.user.password, configs),
                 {:ok, _message} <- PwdValidator.sequential_characters(params.user.password, configs),
                 {:ok, message} <- save_password(user, params.user.password) do
              resp(:ok, message, socket)
            else
              {:error, error} -> resp(:error, error, socket)
            end
        end
  end

  defp save_password(user, password) do
    params = %{auto_pwd: false, password: password}

    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, User.update_password_changeset(user, params))
    |> Repo.transaction()
    |> case do
      {:ok, _multi} ->
        {:ok, "Password Changed Successfully."}

      {:error, _failed_operation, failed_value, _changes_so_far} ->
        reason = Utils.traverse_errors(failed_value.errors)
        {:error, reason}
    end
  end
  def resp(:ok, message, socket) do
    IO.inspect("IAM SUCCESS")

    {:noreply,
     socket
     |> assign(:loader, false)
     |> put_flash(:info, message)
     |> redirect(to: ~p"/")}
  end

  def resp(:error, message, socket) do
    IO.inspect(message, label: "IAM ERROR")

    socket =
      socket
      |> assign(:loader, false)
      |> put_flash(:error, message)
      |> push_redirect(to: ~p"/user/change/password")

    {:noreply, socket}
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end
end
