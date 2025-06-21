defmodule FinincialTool.Repo.Migrations.CreateTblPermissions do
  use Ecto.Migration

  def change do
    create table(:tbl_permissions) do
      add :name, :string, size: 50, null: false
      add :description, :string, size: 150, null: false
      add :type, :string
      add :status, :string
      add :group_id, references(:tbl_permission_groups, column: :id, on_delete: :nothing)
      add :updated_by, references(:tbl_user, column: :id, on_delete: :nothing)
      add :created_by, references(:tbl_user, column: :id, on_delete: :nothing)

      timestamps()
    end
  end
end
