
defmodule FinincialToolWeb.Plugs.Authorizer do
  use FinincialToolWeb, :live_view
  use FinincialToolWeb, :live_component

  alias FinincialTool.Logs
  alias FinincialTool.Roles

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
      FinincialToolWeb.DashboardLive.Index -> nil
      FinincialToolWeb.AccessLive.Index -> "assign_user_roles"
      FinincialToolWeb.RoleLive -> "access_user_roles"

      FinincialToolWeb.SessionLogsLive.Index -> "session_logs"
      FinincialToolWeb.UserLogsLive.Index -> "user_logs"
      FinincialToolWeb.AuditTrailsLive.Index-> "access_logs"
      FinincialToolWeb.UserSessionLogsLive.Index-> "session_logs"
      FinincialToolWeb.ApiLogsLive.Index-> "api_logs"
      FinincialToolWeb.ServiceLogsLive.Index-> "service_logs"

      FinincialToolWeb.UserLive.Index -> "access_users"
      FinincialToolWeb.AccessLive.Index -> "access_user_roles"
      FinincialToolWeb.UserLive.Blocked -> "access_users"
      FinincialToolWeb.ClientUserLive.Index -> "access_users"
      FinincialToolWeb.AccessLive.Index -> "assign_user_roles"
      FinincialToolWeb.RoleLive.Index -> "access_user_roles"
      FinincialToolWeb.PermissionsLive.Index -> "access_permissions"
      FinincialToolWeb.PermissionGroupsLive.Index -> "access_permission_groups"
      FinincialToolWeb.ConfigsLive.Index -> "access_session_configurations"
      FinincialToolWeb.SmsConfigurationsLive.Index -> "access_sms_configurations"
      FinincialToolWeb.PasswordFormatLive.Index -> "access_password_format"
      FinincialToolWeb.ApiIntegratorsLive.Index -> "access_api_integrators"
      FinincialToolWeb.NotificationsLive.Sms -> "access_sms_logs"
      FinincialToolWeb.NotificationsLive.Emails -> "access_email_logs"

      FinincialToolWeb.UserLive.Blocked -> "access_blocked_users"
      FinincialToolWeb.ClientUserLive.Index -> "access_client_users"
      FinincialToolWeb.UserLive.Index -> "access_admin_users"

      FinincialToolWeb.ChatLive.Index -> "access_chats"


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
      FinincialToolWeb.DashboardLive.Index -> "Dashboard"
      FinincialToolWeb.AccessLive.Index ->  "Roles Access Managaement Page"
      FinincialToolWeb.RoleLive -> "Roles Mnanagement page"

      FinincialToolWeb.SessionLogsLive.Index -> "Session Logs Page"
      FinincialToolWeb.UserLogsLive.Index -> "User Logs Page"
      FinincialToolWeb.AuditTrailsLive.Index-> "Access Logs Page"
      FinincialToolWeb.UserSessionLogsLive.Index-> "Session Logs Page"
      FinincialToolWeb.ApiLogsLive.Index-> "API Logs Page"
      FinincialToolWeb.ServiceLogsLive.Index-> "Service Logs Page"

      FinincialToolWeb.UserLive.Index -> "Admin User Management Page"
      FinincialToolWeb.UserLive.Blocked -> "Blocked Users Management Page"
      FinincialToolWeb.ClientUserLive.Index -> "Client Users Management Page"
      FinincialToolWeb.RoleLive.Index -> "Roles Management Page"
      FinincialToolWeb.PermissionsLive.Index -> "Permissions Management Page"
      FinincialToolWeb.PermissionGroupsLive.Index -> "Permission Groups Management Page"
      FinincialToolWeb.ConfigsLive.Index -> "Session Management Page"
      FinincialToolWeb.SmsConfigurationsLive.Index -> "SMS Configurations Page"
      FinincialToolWeb.PasswordFormatLive.Index -> "Password Format Page"
      FinincialToolWeb.ApiIntegratorsLive.Index -> "API Integrators Page"
      FinincialToolWeb.NotificationsLive.Sms -> "SMS Logs Page"
      FinincialToolWeb.NotificationsLive.Emails -> "Email Logs Page"

      FinincialToolWeb.ChatLive.Index -> "Access Chats"

      _ -> "Unknown Page"
    end
  end
end
