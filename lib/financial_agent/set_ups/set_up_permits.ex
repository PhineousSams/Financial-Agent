defmodule FinincialTool.SetUps.SetUpPermissions do
  alias FinincialTool.Repo
  alias FinincialTool.Roles
  alias FinincialTool.Roles.Permissions
  alias FinincialTool.Roles.PermissionGroups

  # FinincialTool.SetUps.SetUpPermissions.permits()



  def permits() do
    [

      %{name: "access_notifications", description: "Access notifications", type: "TYPE1", status: "ACTIVE", group: "NOTIFICATIONS", section: "ACCESS", created_by: 1},
      %{name: "access_sms_logs", description: "Access SMS logs", type: "TYPE1", status: "ACTIVE", group: "NOTIFICATIONS", section: "SMS", created_by: 1},
      %{name: "access_email_logs", description: "Access email logs", type: "TYPE2", status: "ACTIVE", group: "NOTIFICATIONS", section: "EMAIL", created_by: 1},

      %{name: "access_configurations", description: "Access configurations", type: "TYPE1", status: "ACTIVE", group: "MAINTENANCE", section: "CONFIGS", created_by: 1},
      %{name: "manage_configurations", description: "Manage configurations", type: "TYPE2", status: "ACTIVE", group: "MAINTENANCE", section: "MANAGE", created_by: 1},
      %{name: "access_system_settings", description: "Access system settings", type: "TYPE1", status: "ACTIVE", group: "MAINTENANCE", section: "CONFIGS", created_by: 1},


      %{name: "create_permissions", description: "Create permissions", type: "TYPE2", status: "ACTIVE", group: "PERMISSIONS", section: "CREATION", created_by: 1},
      %{name: "approve_permissions", description: "Approve permissions", type: "TYPE2", status: "ACTIVE", group: "PERMISSIONS", section: "APPROVING", created_by: 1},
      %{name: "access_permissions", description: "Access permissions", type: "TYPE1", status: "ACTIVE", group: "PERMISSIONS", section: "MANAGEMENT", created_by: 1},
      %{name: "manage_permissions", description: "Manage permissions", type: "TYPE2", status: "ACTIVE", group: "PERMISSIONS", section: "MANAGE", created_by: 1},

      %{name: "permission_management", description: "Manage permissions", type: "TYPE2", status: "ACTIVE", group: "PERMISSIONS GROUP", section: "MANAGE", created_by: 1},
      %{name: "create_permission_groups", description: "Create permission groups", type: "TYPE2", status: "ACTIVE", group: "PERMISSIONS GROUP", section: "CREATE", created_by: 1},
      %{name: "manage_permission_group", description: "Edit permission group", type: "TYPE1", status: "ACTIVE", group: "PERMISSIONS GROUP", section: "MANAGEMENT", created_by: 1},
      %{name: "access_permission_groups", description: "Access permission groups", type: "TYPE1", status: "ACTIVE", group: "PERMISSIONS GROUP", section: "MANAGEMENT", created_by: 1},

      %{name: "access_user_roles", description: "Access user roles", type: "TYPE2", status: "ACTIVE", group: "ROLES", section: "ACCESS", created_by: 1},
      %{name: "create_user_roles", description: "Create user roles", type: "TYPE2", status: "ACTIVE", group: "ROLES", section: "CREATION", created_by: 1},
      %{name: "assign_user_roles", description: "Assign user roles", type: "TYPE1", status: "ACTIVE", group: "ROLES", section: "MANAGE", created_by: 1},
      %{name: "approve_user_role", description: "Approve user role", type: "TYPE1", status: "ACTIVE", group: "ROLES", section: "MANAGE", created_by: 1},
      %{name: "manage_user_roles", description: "Manage user roles", type: "TYPE1", status: "ACTIVE", group: "ROLES", section: "MANAGE", created_by: 1},


      %{name: "user_logs", description: "View user logs", type: "TYPE2", status: "ACTIVE", group: "LOGS", section: "USER LOGS", created_by: 1},
      %{name: "session_logs", description: "View session logs", type: "TYPE1", status: "ACTIVE", group: "LOGS", section: "SESSION LOGS", created_by: 1},
      %{name: "access_logs", description: "Access logs", type: "TYPE1", status: "ACTIVE", group: "LOGS", section: "ACCESS", created_by: 1},
      %{name: "api_logs", description: "API logs", type: "TYPE1", status: "ACTIVE", group: "LOGS", section: "ACCESS", created_by: 1},
      %{name: "service_logs", description: "Service logs", type: "TYPE1", status: "ACTIVE", group: "LOGS", section: "ACCESS", created_by: 1},

      %{name: "user_management", description: "Manage users", type: "TYPE1", status: "ACTIVE", group: "USERS", section: "MANAGEMENT", created_by: 1},
      %{name: "create_users", description: "Create users", type: "TYPE2", status: "ACTIVE", group: "USERS", section: "CREATION", created_by: 1},
      %{name: "manage_users", description: "Manage users", type: "TYPE1", status: "ACTIVE", group: "USERS", section: "MANAGEMENT", created_by: 1},
      %{name: "approve_users", description: "Approve users", type: "TYPE2", status: "ACTIVE", group: "USERS", section: "MANAGEMENT", created_by: 1},
      %{name: "access_users", description: "Access users", type: "TYPE2", status: "ACTIVE", group: "USERS", section: "MANAGEMENT", created_by: 1},


      %{name: "access_session_configurations", description: "Access session configurations", type: "TYPE1", status: "ACTIVE", group: "SESSION CONFIGURATIONS", section: "ACCESS", created_by: 1},
      %{name: "create_session_configurations", description: "Create session configurations", type: "TYPE2", status: "ACTIVE", group: "SESSION CONFIGURATIONS", section: "CREATION", created_by: 1},
      %{name: "manage_session_configurations", description: "Manage session configurations", type: "TYPE2", status: "ACTIVE", group: "SESSION CONFIGURATIONS", section: "MANAGEMENT", created_by: 1},
      %{name: "approve_session_configurations", description: "Approve session configurations", type: "TYPE2", status: "ACTIVE", group: "SESSION CONFIGURATIONS", section: "APPROVING", created_by: 1},

      %{name: "access_sms_configurations", description: "Access SMS configurations", type: "TYPE1", status: "ACTIVE", group: "SMS CONFIGURATIONS", section: "ACCESS", created_by: 1},
      %{name: "create_sms_configurations", description: "Create SMS configurations", type: "TYPE2", status: "ACTIVE", group: "SMS CONFIGURATIONS", section: "CREATION", created_by: 1},
      %{name: "manage_sms_configurations", description: "Manage SMS configurations", type: "TYPE2", status: "ACTIVE", group: "SMS CONFIGURATIONS", section: "MANAGEMENT", created_by: 1},
      %{name: "approve_sms_configurations", description: "Approve SMS configurations", type: "TYPE2", status: "ACTIVE", group: "SMS CONFIGURATIONS", section: "APPROVING", created_by: 1},


      %{name: "access_api_integrators", description: "Access API Integrators", type: "TYPE1", status: "ACTIVE", group: "API INTEGRATORS", section: "ACCESS", created_by: 1},
      %{name: "create_api_integrators", description: "Create API Integrators", type: "TYPE2", status: "ACTIVE", group: "API INTEGRATORS", section: "CREATION", created_by: 1},
      %{name: "manage_api_integrators", description: "Manage API Integrators", type: "TYPE2", status: "ACTIVE", group: "API INTEGRATORS", section: "MANAGEMENT", created_by: 1},
      %{name: "approve_api_integrators", description: "Approve API Integrators", type: "TYPE2", status: "ACTIVE", group: "API INTEGRATORS", section: "APPROVING", created_by: 1},


      %{name: "access_chats", description: "Access Chats", type: "TYPE1", status: "ACTIVE", group: "CHATS", section: "ACCESS", created_by: 1},
      %{name: "create_chats", description: "Create Chats", type: "TYPE2", status: "ACTIVE", group: "CHATS", section: "CREATION", created_by: 1},
      %{name: "manage_chats", description: "Manage Chats", type: "TYPE2", status: "ACTIVE", group: "CHATS", section: "MANAGEMENT", created_by: 1},


    ]|> Enum.uniq_by(fn %{name: name} -> name end)
    |> Enum.map(&handle_permissions/1)
  end



  defp handle_permissions(permit) do
    case Roles.permission_by_name(permit.name) do
      nil ->
        case Roles.get_by_group_and_section(permit.group, permit.section) do
          nil ->
            case create_group(permit) do
              {:ok, group} -> create_permission(group, permit)
              {:error, changeset} ->
                IO.puts("Failed to create group: #{inspect(permit)}")
                IO.puts("Errors: #{inspect(changeset.errors)}")
            end
          group ->
            create_permission(group, permit)
        end
      _ -> IO.puts("Permission already exists: #{inspect(permit)}")
    end
  end

  def create_group(permit) do
    params = %{
      name: permit.group,
      section: permit.section,
      status: "ACTIVE",
      group: permit.group,
      created_by: 1,
    }
    %PermissionGroups{}
    |> PermissionGroups.changeset(params)
    |> Repo.insert()
  end

  def create_permission(group, permit) do
    %Permissions{}
    |> Permissions.changeset(Map.put(permit, :group_id, group.id))
    |> Repo.insert()
    |> case do
      {:ok, permission} -> IO.puts("Permission created: #{inspect(permission)}")
      {:error, changeset} ->
        IO.puts("Failed to create permission: #{inspect(permit)}")
        IO.puts("Errors: #{inspect(changeset.errors)}")
    end
  end
end
