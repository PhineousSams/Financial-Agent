defmodule FinincialToolWeb.SessionController do
  use FinincialToolWeb, :controller
  import Plug.Conn

  alias FinincialTool.Logs
  alias FinincialTool.Accounts
  alias FinincialToolWeb.Plugs.UserAuth
  alias FinincialTool.Workers.Util.Cache

  def new(conn, _params) do

    conn
    |> render(:new, error_message: nil)
  end

  def create(conn, %{"user" => user_params}) do
    %{"username" => username, "password" => password} = user_params

    case Accounts.get_user_by_username_and_password(conn, username, password) do
      {:error, _message} ->
        render(conn, :new, error_message: "Failed to login, please try again!")

      user ->
        conn
        |> put_flash(:info, "Welcome back!")
        |> UserAuth.log_in_user(user, user_params)
    end
  end

  def login(conn, _params) do
    params = Cache.get(:login)

    with false <- is_nil(Map.get(params, :username)),
         false <- is_nil(Map.get(params, :password)) do
      case Accounts.get_user_by_username_and_password(conn, params.username, params.password) do
        {:error, message} ->
          error_resp(conn, message)

        user ->
          Cache.delete(:login)
          UserAuth.log_in_user(conn, user, params)
      end
    else
      _ -> error_resp(conn, "Failed to login, please try again!")
    end
  end

  defp error_resp(conn, message) do
    Cache.delete(:login)

    conn
    |> put_flash(:error, message)
    |> redirect(to: ~p"/")
  end

  def signout(conn, _params) do
    if is_nil(conn.assigns.current_user) do
      conn
      |> put_flash(:info, "Logged out successfully.")
      |> redirect(to: ~p"/")
    else
      user = Accounts.get_user!(conn.assigns.current_user.id)

      Task.start(fn ->
        Accounts.get_session_by_user_id(user.id)
        |> Enum.map(fn session2 ->
          Logs.find_and_update_session_id_log_out(
            "users_sessions:#{Base.url_encode64(session2.token)}",
            user.id,
            "Logged out successfully"
          )
        end)

        Logs.create_user_logs(%{user_id: user.id, activity: "logged Out"})
      end)

      conn
      |> put_flash(:info, "Logged out successfully.")
      |> UserAuth.log_out_user()
    end
  end
end
