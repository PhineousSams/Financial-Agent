defmodule FinancialAgentWeb.UserLiveAuth do
  @moduledoc false
  use FinancialAgentWeb, :live_view

  alias FinancialAgent.Accounts
  alias FinancialAgent.Notifications

  def mount(_params, %{"user_token" => user_token} = session, socket) do
    socket1 = assign(socket, :browser_id, session["uuid_browser"])

    socket =
      case user_token && Accounts.get_user_by_session_token(user_token, "ADMIN") do
        nil ->
          {:ok, socket1}

        {nil, _} ->
          {:ok, socket1}

        {user, role} ->
          socket =
            assign(socket1, :current_user, user)
            |> assign(:user, user)
            |> assign(:permits, Poison.decode!(role.permissions))
          {:ok, socket}
      end


      case socket do
        {:ok, socket} -> {:cont, socket}
        {:error, _error} ->  {:halt, redirect(socket, to: ~p"/")}
      end
  end

  def on_mount(:default, _params, %{"user_token" => user_token} = session, socket) do
    case fetch_current_user("ADMIN", user_token, session, socket) do
      {:ok, socket} ->
        if user = socket.assigns[:current_user] do
          if user.status == "ACTIVE" do
            {:cont,
             assign(socket, :live_socket_identifier, session["live_socket_id"])
             |> assign(:live_layout_render, :user_session)
             |> assign(remote_ip: session["remote_ip"])
             |> assign(browser_info: session["browser_info"])
             |> assign(user_agent: session["user_agent"])
             |> assign(:nav_type, "CLIENT")}
          else
            {:halt, redirect(socket, to: ~p"/")}
          end
        else
          {:halt, redirect(socket, to: ~p"/")}
        end
      {:error, _error} -> {:halt, redirect(socket, to: ~p"/")}
    end
  end

  def fetch_current_user(type, user_token, session, socket) do
    case user_token && Accounts.get_user_by_session_token(user_token, type) do
      nil ->
        socket = socket |> assign(:browser_id, session["uuid_browser"])
        {:ok, socket}

      {nil, _} ->
        socket =
          socket |> assign(:browser_id, session["uuid_browser"])
        {:ok, socket}

      {user, role} ->
        token =
          Phoenix.Token.sign(%Phoenix.Socket{endpoint: socket.endpoint}, "user socket", user.id)
        socket =
          assign(socket, :current_user, user)
          |> assign(:user, user)
          |> assign(:user_token, token)
          |> assign(show_docs: false)
          |> assign(:permits, Poison.decode!(role.permissions))
          |> assign(:browser_id, session["uuid_browser"])
          |> assign(:alert_count, Notifications.count_staff_alerts())
          |> assign(newest_alerts: Notifications.get_newest_staff_notifications())

        {:ok, socket}

    end
  end
end
