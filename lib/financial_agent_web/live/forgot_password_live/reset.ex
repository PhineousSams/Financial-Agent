defmodule FinincialAgentWeb.ForgotPasswordLive.Reset do
  use FinincialAgentWeb, :live_view

  alias FinincialAgent.Repo
  alias FinincialAgent.Configs
  alias FinincialAgent.Accounts
  alias FinincialAgent.Accounts.User
  alias FinincialAgent.Accounts.UserToken
  alias FinincialAgent.Workers.Util.Utils
  alias FinincialAgent.Workers.Helpers.PwdValidator

  @impl true
  def mount(%{"token" => token}, _session, socket) do
    with {:ok, query} <- verify_token(token),
         {:ok, user} <- get_user(query) do
      user_changeset = %User{}
      changeset = Accounts.password_changeset(user_changeset)

      {:ok,
       socket
       |> assign(:info_modal, false)
       |> assign(error_modal: false)
       |> assign(:user, user)
       |> assign(:login_user, Accounts.get_user!(user.id))
       |> assign_form(changeset)
       |> assign(:token_valid?, true)}
    else
      {:error, _} ->
        {:ok,
         socket
         |> assign(:info_modal, false)
         |> assign(error_modal: false)
         |> assign(:token_valid?, false)}
    end
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
        params = params.user

        case Configs.get_pasword_configs() do
          nil ->
            resp(:error, "System Configurations not Set, Contact System Administrator", socket)

          configs ->
            with {:ok, _} <-
                   User.validate_passwords(
                     user,
                     params.password,
                     params.confirm_password,
                     configs
                   ),
                 {:ok, _message} <- PwdValidator.check_pwd_size(params.password, configs),
                 {:ok, _message} <-
                   PwdValidator.custom_pwd_validation(:numeric, params.password, configs),
                 {:ok, _message} <-
                   PwdValidator.custom_pwd_validation(:special, params.password, configs),
                 {:ok, _message} <-
                   PwdValidator.custom_pwd_validation(:lowercase, params.password, configs),
                 {:ok, _message} <-
                   PwdValidator.custom_pwd_validation(:uppercase, params.password, configs),
                 {:ok, _message} <- PwdValidator.repetitive_characters(params.password, configs),
                 {:ok, _message} <- PwdValidator.sequential_characters(params.password, configs),
                 {:ok, message} <- save_password(user, params.password) do
              resp(:ok, message, socket)
            else
              {:error, error} -> resp(:error, error, socket)
            end
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
     put_flash(socket, :info, message)
     |> redirect(to: ~p"/")}
  end

  def resp(:error, message, socket) do
    IO.inspect(message, label: "IAM ERROR")

    socket =
      socket
      |> put_flash(:error, message)
      |> push_redirect(to: ~p"/user/change/password")

    {:noreply, socket}
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  def get_user(query) do
    case Repo.one(query) do
      nil ->
        {:error, :NOT_FOUND}

      user ->
        {:ok, user}
    end
  end

  def verify_token(token) do
    case UserToken.verify_reset_password_token_query(token) do
      {:ok, user} -> {:ok, user}
      :error -> {:error, :INVALID}
    end
  end
end
