
defmodule FinancialAgentWeb.Plugs.Authorizer do
  use FinancialAgentWeb, :live_view
  use FinancialAgentWeb, :live_component

  alias FinancialAgent.Logs
  alias FinancialAgent.Roles

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
      FinancialAgentWeb.Admin.DashboardLive.Index -> nil
      FinancialAgentWeb.Admin.AccessLive.Index -> "assign_user_roles"
      FinancialAgentWeb.Admin.RoleLive -> "access_user_roles"

      FinancialAgentWeb.Admin.SessionLogsLive.Index -> "session_logs"
      FinancialAgentWeb.Admin.UserLogsLive.Index -> "user_logs"
      FinancialAgentWeb.Admin.AuditTrailsLive.Index-> "access_logs"
      FinancialAgentWeb.Admin.UserSessionLogsLive.Index-> "session_logs"
      FinancialAgentWeb.Admin.ApiLogsLive.Index-> "api_logs"
      FinancialAgentWeb.Admin.ServiceLogsLive.Index-> "service_logs"

      FinancialAgentWeb.Admin.UserLive.Index -> "access_users"
      FinancialAgentWeb.Admin.AccessLive.Index -> "access_user_roles"
      FinancialAgentWeb.Admin.UserLive.Blocked -> "access_users"
      FinancialAgentWeb.Admin.AccessLive.Index -> "assign_user_roles"
      FinancialAgentWeb.Admin.RoleLive.Index -> "access_user_roles"
      FinancialAgentWeb.Admin.PermissionsLive.Index -> "access_permissions"
      FinancialAgentWeb.Admin.PermissionGroupsLive.Index -> "access_permission_groups"
      FinancialAgentWeb.Admin.ConfigsLive.Index -> "access_session_configurations"
      FinancialAgentWeb.Admin.SmsConfigurationsLive.Index -> "access_sms_configurations"
      FinancialAgentWeb.Admin.PasswordFormatLive.Index -> "access_password_format"
      FinancialAgentWeb.Admin.ApiIntegratorsLive.Index -> "access_api_integrators"
      FinancialAgentWeb.Admin.NotificationsLive.Sms -> "access_sms_logs"
      FinancialAgentWeb.Admin.NotificationsLive.Emails -> "access_email_logs"

      FinancialAgentWeb.Admin.UserLive.Blocked -> "access_blocked_users"
      FinancialAgentWeb.Admin.UserLive.Index -> "access_admin_users"

      FinancialAgentWeb.Admin.ChatLive.Index -> "access_chats"


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
      FinancialAgentWeb.Admin.DashboardLive.Index -> "Dashboard"
      FinancialAgentWeb.Admin.AccessLive.Index ->  "Roles Access Managaement Page"
      FinancialAgentWeb.Admin.RoleLive -> "Roles Mnanagement page"

      FinancialAgentWeb.Admin.SessionLogsLive.Index -> "Session Logs Page"
      FinancialAgentWeb.Admin.UserLogsLive.Index -> "User Logs Page"
      FinancialAgentWeb.Admin.AuditTrailsLive.Index-> "Access Logs Page"
      FinancialAgentWeb.Admin.UserSessionLogsLive.Index-> "Session Logs Page"
      FinancialAgentWeb.Admin.ApiLogsLive.Index-> "API Logs Page"
      FinancialAgentWeb.Admin.ServiceLogsLive.Index-> "Service Logs Page"

      FinancialAgentWeb.Admin.UserLive.Index -> "Admin User Management Page"
      FinancialAgentWeb.Admin.UserLive.Blocked -> "Blocked Users Management Page" 
      FinancialAgentWeb.Admin.RoleLive.Index -> "Roles Management Page"
      FinancialAgentWeb.Admin.PermissionsLive.Index -> "Permissions Management Page"
      FinancialAgentWeb.Admin.PermissionGroupsLive.Index -> "Permission Groups Management Page"
      FinancialAgentWeb.Admin.ConfigsLive.Index -> "Session Management Page"
      FinancialAgentWeb.Admin.SmsConfigurationsLive.Index -> "SMS Configurations Page"
      FinancialAgentWeb.Admin.PasswordFormatLive.Index -> "Password Format Page"
      FinancialAgentWeb.Admin.ApiIntegratorsLive.Index -> "API Integrators Page"
      FinancialAgentWeb.Admin.NotificationsLive.Sms -> "SMS Logs Page"
      FinancialAgentWeb.Admin.NotificationsLive.Emails -> "Email Logs Page"

      FinancialAgentWeb.Admin.ChatLive.Index -> "Access Chats"

      _ -> "Unknown Page"
    end
  end
end
