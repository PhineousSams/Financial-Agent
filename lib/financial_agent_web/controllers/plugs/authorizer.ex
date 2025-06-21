
defmodule FinincialAgentWeb.Plugs.Authorizer do
  use FinincialAgentWeb, :live_view
  use FinincialAgentWeb, :live_component

  alias FinincialAgent.Logs
  alias FinincialAgent.Roles

  def on_mount(_params, session, socket) do
    # Use the socket's live_view module name for permission checking
    live_view_name = socket.view

    case authorize_user(socket, session, live_view_name) do
      {:ok, socket} ->
        {:cont, socket}

      {:error, socket} ->

        {:halt,
        socket
          |> put_flash(:error, "Access denied: you do not have the required permissions!")
          |> push_redirect(to: "/Admin/dashboard")}
    end
  end

  def on_mount(:default, _params, %{"user_token" => _user_token} = session, socket) do
    live_view_name = socket.view

    case authorize_user(socket, session, live_view_name) do
      {:ok, socket} ->
        {:cont, socket}  # Continue mounting the LiveView

      {:error, socket} ->
        {:halt,
        socket
          |> put_flash(:error, "Access denied: you do not have the required permissions!")
          |> push_redirect(to: "/Admin/dashboard")
          }
    end
  end

  defp authorize_user(socket, session, live_view_name) do
    required_permission = get_required_permission(live_view_name)

    case socket.assigns do
      %{current_user: current_user} ->
        user_role_with_permissions = Roles.get_user_role_by_id_with_permissions(current_user.role_id)

        if is_nil(required_permission) do
            {:ok, socket}
        else
          if Enum.member?(user_role_with_permissions.permissions, required_permission) do
            Task.start(fn -> async_log_access(session, current_user.id, live_view_name, "Access Granted", required_permission) end)
            {:ok, socket}
          else
            Task.start(fn -> async_log_access(session, current_user.id, live_view_name, "Access Denied", required_permission) end)
            {:error, socket}
          end
        end

      _ ->
        {:error, socket}
    end
  end

  defp get_required_permission(live_view_name) do
    case live_view_name do
      FinincialAgentWeb.DashboardLive.Index -> nil
      FinincialAgentWeb.AccessLive.Index -> "assign_user_roles"
      FinincialAgentWeb.RoleLive -> "access_user_roles"

      FinincialAgentWeb.SessionLogsLive.Index -> "session_logs"
      FinincialAgentWeb.UserLogsLive.Index -> "user_logs"
      FinincialAgentWeb.AuditTrailsLive.Index-> "access_logs"
      FinincialAgentWeb.UserSessionLogsLive.Index-> "session_logs"
      FinincialAgentWeb.ApiLogsLive.Index-> "api_logs"
      FinincialAgentWeb.ServiceLogsLive.Index-> "service_logs"

      FinincialAgentWeb.UserLive.Index -> "access_users"
      FinincialAgentWeb.AccessLive.Index -> "access_user_roles"
      FinincialAgentWeb.UserLive.Blocked -> "access_users"
      FinincialAgentWeb.ClientUserLive.Index -> "access_users"
      FinincialAgentWeb.AccessLive.Index -> "assign_user_roles"
      FinincialAgentWeb.RoleLive.Index -> "access_user_roles"
      FinincialAgentWeb.PermissionsLive.Index -> "access_permissions"
      FinincialAgentWeb.PermissionGroupsLive.Index -> "access_permission_groups"
      FinincialAgentWeb.ConfigsLive.Index -> "access_session_configurations"
      FinincialAgentWeb.SmsConfigurationsLive.Index -> "access_sms_configurations"
      FinincialAgentWeb.PasswordFormatLive.Index -> "access_password_format"
      FinincialAgentWeb.ApiIntegratorsLive.Index -> "access_api_integrators"
      FinincialAgentWeb.NotificationsLive.Sms -> "access_sms_logs"
      FinincialAgentWeb.NotificationsLive.Emails -> "access_email_logs"

      FinincialAgentWeb.UserLive.Blocked -> "access_blocked_users"
      FinincialAgentWeb.ClientUserLive.Index -> "access_client_users"
      FinincialAgentWeb.UserLive.Index -> "access_admin_users"

      FinincialAgentWeb.ChatLive.Index -> "access_chats"


      _ -> "unknown_role"

    end
  end

  defp async_log_access(session, user_id, live_view_name, status, required_permission) do
      params =  %{}

      log_message = generate_log_message(live_view_name, status)

      Logs.system_log_session(
        session,
        log_message,
        status,
        params,
        "Access Control: #{required_permission}",
        user_id
      )
  end


  # Helper function to generate user-friendly log messages
  defp generate_log_message(live_view_name, status) do
    action = case status do
      "Access Granted" -> "Accessed"
      "Access Denied" -> "Attempted to access"
    end

    "#{action} #{live_view_display_name(live_view_name)}"
  end

  # Function to get a friendly name for the LiveView
  defp live_view_display_name(live_view_name) do
    case live_view_name do
      FinincialAgentWeb.DashboardLive.Index -> "Dashboard"
      FinincialAgentWeb.AccessLive.Index ->  "Roles Access Managaement Page"
      FinincialAgentWeb.RoleLive -> "Roles Mnanagement page"

      FinincialAgentWeb.SessionLogsLive.Index -> "Session Logs Page"
      FinincialAgentWeb.UserLogsLive.Index -> "User Logs Page"
      FinincialAgentWeb.AuditTrailsLive.Index-> "Access Logs Page"
      FinincialAgentWeb.UserSessionLogsLive.Index-> "Session Logs Page"
      FinincialAgentWeb.ApiLogsLive.Index-> "API Logs Page"
      FinincialAgentWeb.ServiceLogsLive.Index-> "Service Logs Page"

      FinincialAgentWeb.UserLive.Index -> "Admin User Management Page"
      FinincialAgentWeb.UserLive.Blocked -> "Blocked Users Management Page"
      FinincialAgentWeb.ClientUserLive.Index -> "Client Users Management Page"
      FinincialAgentWeb.RoleLive.Index -> "Roles Management Page"
      FinincialAgentWeb.PermissionsLive.Index -> "Permissions Management Page"
      FinincialAgentWeb.PermissionGroupsLive.Index -> "Permission Groups Management Page"
      FinincialAgentWeb.ConfigsLive.Index -> "Session Management Page"
      FinincialAgentWeb.SmsConfigurationsLive.Index -> "SMS Configurations Page"
      FinincialAgentWeb.PasswordFormatLive.Index -> "Password Format Page"
      FinincialAgentWeb.ApiIntegratorsLive.Index -> "API Integrators Page"
      FinincialAgentWeb.NotificationsLive.Sms -> "SMS Logs Page"
      FinincialAgentWeb.NotificationsLive.Emails -> "Email Logs Page"

      FinincialAgentWeb.ChatLive.Index -> "Access Chats"

      _ -> "Unknown Page"
    end
  end
end
