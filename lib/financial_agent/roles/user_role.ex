defmodule FinincialTool.Roles.UserRole do
  use Ecto.Schema
  import Ecto.Changeset

  use Endon

  alias FinincialTool.Roles
  alias FinincialTool.Roles.UserRole
  alias FinincialTool.Workers.Util.Helpers

  @columns ~w(id name description permissions editable status
  created_by updated_by inserted_at updated_at)a

  schema "tbl_user_role" do
    field :name, :string
    field :description, :string
    field :permissions, :string
    field :editable, :boolean
    field :status, :string, default: "PENDING_CONFIGURATION"
    field :created_by, :id
    field :updated_by, :id

    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, @columns)
  end

  def registration_changeset(role, attrs, _opts \\ []) do
    role
    |> cast(attrs, @columns)
    |> validate_required([:name, :description])
    |> validate_role_id()
    |> validate_length(:name, min: 3, max: 50)
    |> validate_length(:description, min: 3, max: 150)
    |> unsafe_validate_unique([:name], FinincialTool.Repo)
    |> unique_constraint([:name])
  end

  def update_status_changeset(role, attrs) do
    role
    |> cast(attrs, [:status])
    |> validate_role_pen(role)
    |> case do
      %{changes: %{status: _}} = changeset -> changeset
      %{} = changeset -> add_error(changeset, :status, "did not change")
    end
  end

  def update_permission_changeset(role, attrs, user \\ %{role_id: 1}) do
    role
    |> cast(attrs, [:permissions])
    |> validate_permissions(role)
    |> validate_user_user_performing_action(user, role)
    |> validate_role_pen(role)
    |> case do
      %{changes: %{permissions: _}} = changeset -> changeset
      %{} = changeset -> add_error(changeset, :permissions, "did not change")
    end
  end

  def update_role_changeset(role, attrs) do
    role
    |> cast(attrs, @columns)
    |> validate_required([:name])
    |> validate_role_id_update(role)
    |> validate_length(:name, min: 3, max: 50)
    |> validate_length(:description, min: 3, max: 150)
    |> case do
      %{changes: %{name: _}} = changeset -> changeset
      %{changes: %{description: _}} = changeset -> changeset
      %{} = changeset -> add_error(changeset, :role, "did not change")
    end
  end

  defp validate_permissions(struct, _role) do
    permissions = get_change(struct, :permissions)

    if permissions != nil do
      all_permissions = Roles.get_all_permissions()


      status =
        Enum.map(Poison.decode!(permissions), &Enum.member?(all_permissions, &1))
        |> Enum.member?(false)

      if status == true,
        do: add_error(struct, :permissions, "has been compromised"),
        else: put_change(struct, :permissions, permissions)
    else
      struct
    end
  end

  defp validate_user_user_performing_action(changeset, user, current) do
    if current.name == "SUPER_USER" do
      changeset
    else
      if user.role_id == current.id do
        add_error(changeset, :action, "not allowed by this user")
      else
        changeset
      end
    end
  end

  defp validate_role_pen(changeset, role) do
    if role.editable == true,
      do: changeset,
      else: add_error(changeset, :role, "can not be edited")
  end

  def validate_role_id(struck) do
    id = get_change(struck, :system_role_id)

    if id == 3 or id == "3",
      do: add_error(struck, :role, "can not be created due to insufficient privileges"),
      else: struck
  end

  def validate_role_id_update(struck, %UserRole{id: id}) do
    if id == 3 or id == "3",
      do: add_error(struck, :role, "can not be created due to insufficient privileges"),
      else: struck
  end

  def approve_record(user, attrs) do
    user
    |> cast(attrs, @columns)
  end
end
