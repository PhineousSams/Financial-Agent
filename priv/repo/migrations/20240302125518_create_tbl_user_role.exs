defmodule FinincialAgent.Repo.Migrations.CreateTblUserRole do
  use Ecto.Migration

  def change do
    create table(:tbl_user_role) do
      add :name, :string, size: 50, null: false
      add :status, :string
      add :editable, :boolean
      add :created_by, :id
      add :updated_by, :id
      add :description, :string, size: 150, null: false
      add :permissions, :text, default: "[]"

      timestamps()
    end
  end
end
