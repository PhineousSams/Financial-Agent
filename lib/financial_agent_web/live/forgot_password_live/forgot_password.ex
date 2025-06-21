defmodule FinincialToolWeb.ForgotPasswordLive.Index do
  use FinincialToolWeb, :live_view
  alias FinincialTool.Accounts
  alias FinincialTool.Accounts.User
  alias FinincialTool.Accounts.UserToken
  alias FinincialTool.Repo
  alias FinincialTool.Notifications.Email

  @impl true
  def mount(_params, _session, socket) do
    changeset = User.forgot_password_changeset(%User{}, %{})
    {:ok, assign(socket, :form, to_form(changeset))}
  end

  @impl true
  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset =
      %User{}
      |> User.forgot_password_changeset(user_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form, to_form(changeset))}
  end

  @impl true
  def handle_event("submit", %{"user" => user_params}, socket) do
    case process_forgot_password(user_params) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(
           :info,
           "If an account exists for this username, you will receive password reset instructions shortly."
         )
         |> redirect(to: "/")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  defp process_forgot_password(%{"username" => username} = params) do
    changeset = User.forgot_password_changeset(%User{}, params)

    if changeset.valid? do
      case Accounts.get_by_username(username) do
        nil ->
          # We do not reveal that the user does not exist for security reasons
          {:ok, :user_not_found}

        user ->
          send_password_reset_instructions(user)
          {:ok, user}
      end
    else
      {:error,
       changeset
       |> Map.put(:action, :validate)}
    end
  end

  def send_password_reset_instructions(user) do
    {token, token_record} = UserToken.build_reset_password_token(user)
    app_url = Application.get_env(:financial_tool, :base_url)
    base_url = "#{app_url}/forgot/password/reset/#{token}"
    dbg(base_url)

    Ecto.Multi.new()
    |> Ecto.Multi.insert(:hashed_token, token_record)
    |> handle_email(user.email, base_url, "FORGOT PASSWORD RESET")
    |> Repo.transaction()
  end

  defp handle_email(multi, email, msg, type) do
    params = %{
      mail_body: msg,
      recipient_email: email,
      sender_email: "ceec@gmail.com",
      sender_name: "Ceec",
      status: "PENDING",
      subject: type
    }

    Ecto.Multi.insert(multi, :forgot_password_email, Email.changeset(%Email{}, params))
  end

  def render(assigns) do
    ~H"""
    <div class="py-5 font-[sans-serif]">
      <div class="flex flex-col items-center justify-center py-6 px-4">
        <div class="max-w-md w-full">
          <.link href={~p"/Admin/dashboard"}>
            <img src="/images/ceeclogo.png" alt="logo" class="w-40 mb-8 mx-auto block" />
          </.link>
          <div class="p-8 rounded-2xl bg-white shadow">
            <h1 class="text-gray-800 text-center text-2xl font-bold">
              Reset Password
            </h1>
            <.simple_form
              for={@form}
              id="forgot-password-form"
              phx-change="validate"
              phx-submit="submit"
            >
              <.input
                field={@form[:username]}
                type="text"
                label="Enter your username"
                placeholder="Enter username"
              />
              <.error_tag form={@form} field={:username} />

              <:actions>
                <.button phx-disable-with="Submitting..." class="bg-green-600 hover:bg-green-800">
                  Reset Password
                </.button>
              </:actions>
            </.simple_form>
          </div>
        </div>
      </div>
    </div>
    <!-- Footer -->
    <div class="position-absolute pos-bottom pos-left pos-right p-3 text-center text-black">
      <%= Timex.today().year %> © CEEC. All Rights Reserved
    </div>
    """
  end
end
