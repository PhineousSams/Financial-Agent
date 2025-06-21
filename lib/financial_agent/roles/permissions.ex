defmodule FinancialAgent.Roles.Permissions do
  use Ecto.Schema
  import Ecto.Changeset

  schema "tbl_permissions" do
    field :name, :string
    field :description, :string
    field :status, :string
    field :type, :string
    belongs_to :group, FinancialAgent.Roles.PermissionGroups, foreign_key: :group_id, type: :id
    belongs_to :updater, FinancialAgent.Accounts.User, foreign_key: :updated_by, type: :id
    belongs_to :maker, FinancialAgent.Accounts.User, foreign_key: :created_by, type: :id

    timestamps()
  end

  @doc false
  def changeset(permissions, attrs) do
    permissions
    |> cast(attrs, [:name, :description, :status, :type, :group_id, :updated_by, :created_by])
    |> validate_required([:name, :description, :group_id])
    |> unique_constraint(:name)
  end
end
