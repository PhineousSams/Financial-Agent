defmodule FinincialAgent.Roles do
  import Ecto.Query, warn: false
  @pagination [page_size: 10]

  alias FinincialAgent.Repo
  alias FinincialAgent.Logs
  alias FinincialAgent.Roles.UserRole
  alias FinincialAgent.Workers.Util.Utils
  alias FinincialAgent.Roles.Permissions
  alias FinincialAgent.Roles.PermissionGroups

  # ============================ USER ROLES ===========================
  def get_user_role_name_by_id_with_permissions(data) do
    if data == nil do
      []
    else
      Map.merge(data, %{permissions: Poison.decode!(data.permissions)})
    end
  end

  def get_user_role_by_id_with_permissions(id) do
    data = get_user_role_by_id(id)

    if data == nil,
      do: %{permissions: []},
      else: Map.merge(data, %{permissions: Poison.decode!(data.permissions)})
  end

  def get_user_role_permissions(role),
    do: get_user_role_by_id_with_permissions(role.id).permissions

  def update_user_role_permissions(permissions, id, user, multiple \\ Ecto.Multi.new()) do
    multiple
    |> Ecto.Multi.run(:role, fn _repo, _ ->
      {:ok, get_user_role_by_id(id)}
    end)
    |> Ecto.Multi.update(:update, fn %{role: role} ->
      UserRole.update_permission_changeset(
        role,
        %{permissions: Poison.encode!(permissions)},
        user
      )
    end)
    |> Repo.transaction()
  end

  def get_user_role_by_id(id) do
    UserRole
    |> where([a], a.id == ^id)
    |> Repo.one()
  end

  def get_user_role_by_id_preload(id) do
    UserRole
    |> where([a], a.id == ^id)
    |> Repo.one()
  end

  def register_user_role(socket, attrs) do
    register_user_role_multi(Ecto.Multi.new(), attrs)
    |> Logs.system_log_session_live_multi(
      socket,
      "Create User Role [#{attrs["name"]}]",
      "CREATE",
      attrs,
      "User Role Management"
    )
    |> Repo.transaction()
  end

  def register_user_role_multi(multi, attrs) do
    Ecto.Multi.insert(multi, :document, UserRole.registration_changeset(%UserRole{}, attrs))
  end

  def user_roles(search_params) do
    UserRole
    |> where([u], u.status != "DELETED")
    |> handle_role_filter(search_params)
    |> order_by(desc: :inserted_at)
    |> compose_role_select()
    |> Scrivener.paginate(Scrivener.Config.new(Repo, @pagination, search_params))
  end

  defp handle_role_filter(query, params) do
    Enum.reduce(params, query, fn
      {"isearch", value}, query when byte_size(value) > 0 ->
        role_isearch_filter(query, Utils.sanitize_term(value))

      {"name", value}, query when byte_size(value) > 0 ->
        where(query, [a], fragment("lower(?) LIKE lower(?)", a.name, ^Utils.sanitize_term(value)))

      {"description", value}, query when byte_size(value) > 0 ->
        where(
          query,
          [a],
          fragment("lower(?) LIKE lower(?)", a.description, ^Utils.sanitize_term(value))
        )

      {"status", value}, query when byte_size(value) > 0 ->
        where(
          query,
          [a],
          fragment("lower(?) LIKE lower(?)", a.status, ^Utils.sanitize_term(value))
        )

      {"from", value}, query when byte_size(value) > 0 ->
        where(query, [a], fragment("CAST(? AS DATE) >= ?", a.inserted_at, ^value))

      {"to", value}, query when byte_size(value) > 0 ->
        where(query, [a], fragment("CAST(? AS DATE) <= ?", a.inserted_at, ^value))

      {_, _}, query ->
        # Not a where parameter
        query
    end)
  end

  defp role_isearch_filter(query, search_term) do
    where(
      query,
      [a],
      fragment("lower(?) LIKE lower(?)", a.name, ^search_term) or
        fragment("lower(?) LIKE lower(?)", a.description, ^search_term) or
        fragment("lower(?) LIKE lower(?)", a.status, ^search_term)
    )
  end

  defp compose_role_select(query) do
    query
    |> select(
      [u],
      map(u, [
        :id,
        :name,
        :description,
        :permissions,
        :status,
        :created_by,
        :updated_by,
        :inserted_at,
        :updated_at
      ])
    )
  end

  def list_user_roles do
    UserRole
    |> where([role], role.id != 0)
    |> Repo.all()
  end

  def list_user_role do
    Repo.all(UserRole)
  end

  def get_user_role!(id), do: Repo.get!(UserRole, id)

  def create_user_role(attrs \\ %{}) do
    %UserRole{}
    |> UserRole.changeset(attrs)
    |> Repo.insert()
  end

  def update_user_role(%UserRole{} = user_role, attrs) do
    user_role
    |> UserRole.changeset(attrs)
    |> Repo.update()
  end

  def delete_user_role(%UserRole{} = user_role) do
    Repo.delete(user_role)
  end

  def register_user_roles(%UserRole{} = user_role, attrs \\ %{}) do
    UserRole.registration_changeset(user_role, attrs)
  end

  def change_user_role(%UserRole{} = user_role, attrs \\ %{}) do
    UserRole.registration_changeset(user_role, attrs)
  end

  # ==================== PERMISSIONS ============================
  def permission_by_name(name) do
    Permissions
    |> where([a], a.name == ^name)
    |> limit(1)
    |> Repo.one()
  end

  def get_all_permissions, do: Permissions |> select([a], a.name) |> Repo.all()

  # def get_filter_permissions(query),
  #   do:
  #     Permissions
  #     |> where([a], like(a.name, ^"%#{query}%"))
  #     |> select([a], a.name)
  #     |> Repo.all()

  def get_filter_permissions(query),
    do:
      Permissions
      |> join(:left, [a], b in "tbl_permission_groups", on: a.group_id == b.id)
      |> where([a, _b], a.status == "ACTIVE" and like(a.name, ^"%#{query}%"))
      |> select([a, b], %{
        id: a.id,
        name: a.name,
        group: b.group
      })
      |> Repo.all()

  def get_permissions_with_groups() do
    Permissions
    |> join(:left, [a], b in "tbl_permission_groups", on: a.group_id == b.id)
    |> where([a, _b], a.status == "ACTIVE")
    |> select([a, b], %{
      id: a.id,
      name: a.name,
      group: b.group
    })
    |> Repo.all()
  end

  def get_permissions(search_params) do
    Permissions
    |> join(:left, [a], b in "tbl_permission_groups", on: a.group_id == b.id)
    |> where([a, _b], a.status != "DELETED")
    |> handle_permissions_filter(search_params)
    |> order_by(desc: :inserted_at)
    |> compose_permissions_select()
    |> select_merge([_a, b], %{group_name: b.group, section_name: b.section})
    |> Scrivener.paginate(Scrivener.Config.new(Repo, @pagination, search_params))
  end

  defp handle_permissions_filter(query, params) do
    Enum.reduce(params, query, fn
      {"isearch", value}, query when byte_size(value) > 0 ->
        permissions_isearch_filter(query, Utils.sanitize_term(value))

      {"name", value}, query when byte_size(value) > 0 ->
        where(query, [a], fragment("lower(?) LIKE lower(?)", a.name, ^Utils.sanitize_term(value)))

      {"description", value}, query when byte_size(value) > 0 ->
        where(
          query,
          [a],
          fragment("lower(?) LIKE lower(?)", a.description, ^Utils.sanitize_term(value))
        )

      {"type", value}, query when byte_size(value) > 0 ->
        where(query, [a], fragment("lower(?) LIKE lower(?)", a.type, ^Utils.sanitize_term(value)))

      {"status", value}, query when byte_size(value) > 0 ->
        where(
          query,
          [a],
          fragment("lower(?) LIKE lower(?)", a.status, ^Utils.sanitize_term(value))
        )

      {"from", value}, query when byte_size(value) > 0 ->
        where(query, [a], fragment("CAST(? AS DATE) >= ?", a.inserted_at, ^value))

      {"to", value}, query when byte_size(value) > 0 ->
        where(query, [a], fragment("CAST(? AS DATE) <= ?", a.inserted_at, ^value))

      {_, _}, query ->
        # Not a where parameter
        query
    end)
  end

  defp permissions_isearch_filter(query, search_term) do
    where(
      query,
      [a],
      fragment("lower(?) LIKE lower(?)", a.name, ^search_term) or
        fragment("lower(?) LIKE lower(?)", a.description, ^search_term) or
        fragment("lower(?) LIKE lower(?)", a.type, ^search_term) or
        fragment("lower(?) LIKE lower(?)", a.status, ^search_term)
    )
  end

  defp compose_permissions_select(query) do
    query
    |> select(
      [u],
      map(u, [
        :id,
        :name,
        :description,
        :type,
        :status,
        :created_by,
        :updated_by,
        :inserted_at,
        :updated_at
      ])
    )
  end

  def list_tbl_permissions do
    Repo.all(Permissions)
  end

  def get_permissions!(id), do: Repo.get!(Permissions, id)

  def create_permissions(socket, attrs) do
    register_permissions_multi(Ecto.Multi.new(), attrs)
    |> Logs.system_log_session_live_multi(
      socket,
      "Create PermissionS [#{attrs["name"]}]",
      "CREATE",
      attrs,
      "Permissions Management"
    )
    |> Repo.transaction()
  end

  def register_permissions_multi(multi, attrs) do
    Ecto.Multi.insert(multi, :document, Permissions.changeset(%Permissions{}, attrs))
  end

  def create_permissions(attrs \\ %{}) do
    %Permissions{}
    |> Permissions.changeset(attrs)
    |> Repo.insert()
  end

  def update_permissions(%Permissions{} = permissions, attrs) do
    permissions
    |> Permissions.changeset(attrs)
    |> Repo.update()
  end

  def delete_permissions(%Permissions{} = permissions) do
    Repo.delete(permissions)
  end

  def change_permissions(%Permissions{} = permissions, attrs \\ %{}) do
    Permissions.changeset(permissions, attrs)
  end

  # ================== PERMISSION GROUPS ======================
  def get_by_group_and_section(group, section) do
    PermissionGroups
    |> where([a], a.group == ^group and a.section == ^section)
    |> limit(1)
    |> Repo.one()
  end

  def get_permissions_group(search_params) do
    PermissionGroups
    |> where([u], u.status != "DELETED")
    |> handle_group_permissions_filter(search_params)
    |> order_by(desc: :inserted_at)
    |> compose_group_permissions_select()
    |> Scrivener.paginate(Scrivener.Config.new(Repo, @pagination, search_params))
  end

  defp handle_group_permissions_filter(query, params) do
    Enum.reduce(params, query, fn
      {"isearch", value}, query when byte_size(value) > 0 ->
        group_permissions_isearch_filter(query, Utils.sanitize_term(value))

      {"group", value}, query when byte_size(value) > 0 ->
        where(
          query,
          [a],
          fragment("lower(?) LIKE lower(?)", a.group, ^Utils.sanitize_term(value))
        )

      {"section", value}, query when byte_size(value) > 0 ->
        where(
          query,
          [a],
          fragment("lower(?) LIKE lower(?)", a.section, ^Utils.sanitize_term(value))
        )

      {"status", value}, query when byte_size(value) > 0 ->
        where(
          query,
          [a],
          fragment("lower(?) LIKE lower(?)", a.status, ^Utils.sanitize_term(value))
        )

      {"from", value}, query when byte_size(value) > 0 ->
        where(query, [a], fragment("CAST(? AS DATE) >= ?", a.inserted_at, ^value))

      {"to", value}, query when byte_size(value) > 0 ->
        where(query, [a], fragment("CAST(? AS DATE) <= ?", a.inserted_at, ^value))

      {_, _}, query ->
        # Not a where parameter
        query
    end)
  end

  defp group_permissions_isearch_filter(query, search_term) do
    where(
      query,
      [a],
      fragment("lower(?) LIKE lower(?)", a.group, ^search_term) or
        fragment("lower(?) LIKE lower(?)", a.section, ^search_term) or
        fragment("lower(?) LIKE lower(?)", a.status, ^search_term)
    )
  end

  defp compose_group_permissions_select(query) do
    query
    |> select(
      [u],
      map(u, [
        :id,
        :group,
        :section,
        :status,
        :created_by,
        :updated_by,
        :inserted_at,
        :updated_at
      ])
    )
  end

  def get_permission_groups do
    PermissionGroups
    |> where([u], u.status != "DELETED")
    |> Repo.all()
  end

  def list_tbl_permission_groups do
    PermissionGroups
    |> where([pg], pg.status != "DELETED")
    |> Repo.all()
  end

  def get_permission_groups!(id), do: Repo.get!(PermissionGroups, id)

  def create_permission_groups(socket, attrs) do
    register_permission_group_multi(Ecto.Multi.new(), attrs)
    |> Logs.system_log_session_live_multi(
      socket,
      "Create Permission Group [#{attrs["group"]}]",
      "CREATE",
      attrs,
      "Permission Group Management"
    )
    |> Repo.transaction()
  end

  def register_permission_group_multi(multi, attrs) do
    Ecto.Multi.insert(multi, :document, PermissionGroups.changeset(%PermissionGroups{}, attrs))
  end

  def create_permission_groups(attrs \\ %{}) do
    %PermissionGroups{}
    |> PermissionGroups.changeset(attrs)
    |> Repo.insert()
  end

  def update_permission_groups(%PermissionGroups{} = permission_groups, attrs) do
    permission_groups
    |> PermissionGroups.changeset(attrs)
    |> Repo.update()
  end

  def delete_permission_groups(%PermissionGroups{} = permission_groups) do
    Repo.delete(permission_groups)
  end

  def change_permission_groups(%PermissionGroups{} = permission_groups, attrs \\ %{}) do
    PermissionGroups.changeset(permission_groups, attrs)
  end
end
