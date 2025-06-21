defmodule FinincialAgent.Repo.Migrations.CreateTblPermissionGroup do
  use Ecto.Migration

  def change do
    create table(:tbl_permission_groups) do
      add :group, :string, null: false
      add :section, :string, null: false
      add :status, :string
      add :updated_by, references(:tbl_user, column: :id, on_delete: :nothing)
      add :created_by, references(:tbl_user, column: :id, on_delete: :nothing)
      timestamps()
    end
  end
end
