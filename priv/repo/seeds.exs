alias FinincialAgent.Accounts
alias FinincialAgent.Roles.UserRole
alias FinincialAgent.Roles.PermissionGroups
alias FinincialAgent.Settings.ConfigSettings
alias FinincialAgent.SetUps.SetUpConfigs
alias FinincialAgent.SetUps.SetUpDirectory
alias FinincialAgent.SetUps.SetUpLocations
alias FinincialAgent.SetUps.SetUpPassword
alias FinincialAgent.SetUps.SetUpPermissions
alias FinincialAgent.SetUps.SetUpProvincialCentres
# mix run priv/repo/seeds.exs

encode_data = fn data -> data |> Poison.encode!() end

multiple = Ecto.Multi.new()

post_send = fn query, text ->
  FinincialAgent.Repo.transaction(query)
  |> case do
    {:ok, _} ->
      IO.inspect(":ok", label: text)

    {:error, v, error, _} ->
      IO.inspect(error, label: :error)
      IO.inspect(v, label: :function)
  end
end

FinincialAgent.Repo.insert!(%UserRole{
  name: "SUPER_USER",
  description: "Super user",
  editable: true,
  permissions:
    encode_data.([
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
    ]),
  status: "ACTIVE"
})

Accounts.register_user(%{
  first_name: "Admin",
  last_name: "Admin",
  username: "admin",
  email: "admin@gmail.com",
  password: "password06",
  auto_pwd: false,
  sex: "M",
  dob: Timex.today(),
  id_no: "101010/27/1",
  phone: "260974994432",
  status: "ACTIVE",
  user_status: "ACTIVE",
  blocked: false,
  user_type: "BACKOFFICE",
  role_id: 1
})

configs = [
  %{
    name: "login_failed_attempts_max",
    value_type: "times",
    value: "3",
    description: "Maxmum login attempt count",
    inserted_at: NaiveDateTime.truncate(NaiveDateTime.utc_now(), :second),
    updated_at: NaiveDateTime.truncate(NaiveDateTime.utc_now(), :second)
  },
  %{
    name: "user_inactive_session_notification",
    value_type: "minutes",
    value: "100",
    description: "Notify the user when the page is inactive in x interval",
    inserted_at: NaiveDateTime.truncate(NaiveDateTime.utc_now(), :second),
    updated_at: NaiveDateTime.truncate(NaiveDateTime.utc_now(), :second)
  },
  %{
    name: "inactive_user_model_timeout",
    value_type: "minutes",
    value: "100",
    description: "Notify the user when the page is inactive in x interval",
    inserted_at: NaiveDateTime.truncate(NaiveDateTime.utc_now(), :second),
    updated_at: NaiveDateTime.truncate(NaiveDateTime.utc_now(), :second)
  }
]

multiple
|> Ecto.Multi.insert_all(:config, ConfigSettings, configs)
|> post_send.("CONFIGURATIONS")

SetUpPassword.insert_password_maintenance()
SetUpPermissions.permits()
