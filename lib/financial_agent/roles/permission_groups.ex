defmodule FinincialAgent.Roles.PermissionGroups do
  use Ecto.Schema
  import Ecto.Changeset

  schema "tbl_permission_groups" do
    field :group, :string
    field :section, :string
    field :status, :string
    belongs_to :updater, FinincialAgent.Accounts.User, foreign_key: :updated_by, type: :id
    belongs_to :maker, FinincialAgent.Accounts.User, foreign_key: :created_by, type: :id

    timestamps()
  end

  @doc false
  def changeset(permission_groups, attrs) do
    permission_groups
    |> cast(attrs, [:group, :section, :status, :updated_by, :created_by])
    |> validate_required([:group, :section])
  end
end
