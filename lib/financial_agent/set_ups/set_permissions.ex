defmodule FinancialAgent.SetUps.Permissions do

  alias FinancialAgent.Repo
  alias FinancialAgent.Roles
  alias FinancialAgent.Roles.UserRole


  # FinancialAgent.SetUps.Permissions.setup_permissions()
  def setup_permissions() do
    role = Repo.get_by(UserRole, id: 1)
    Roles.update_user_role(role, %{permissions: permissions()})
  end

  defp permissions() do
    encode_data().([
      "session_logs",
      "access_user_roles",
      "approve_user_role",
      "user_logs",
      "manage_users",
      "create_permissions",
      "access_logs",
      "approve_permission_group",
      "reject_permission_group",
      "create_permission_groups",
      "edit_permission_group",
      "view_permission_group",
      "activate_permission_group",
      "disable_permission_group",
      "delete_permission_group",
      "manage_permissions",
      "create_user_roles",
      "manage_user_roles",
      "create_users",
      "access_permissions",
      "access_notifications",
      "access_users",
      "assign_user_roles",
      "approve_permissions",
      "access_sms_logs",
      "access_email_logs",
      "user_management",
      "approve_users",
      "dashboard",
      "access_api_integrators",
      "access_password_format",
      "access_blocked_users",
      "access_admin_users",
      "access_configurations",
      "access_system_settings",
      "access_sms_configurations",
      "access_session_configurations"
    ])
  end

  defp encode_data() do
    fn data -> data |> Poison.encode!() end
  end

end
