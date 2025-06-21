defmodule FinincialTool.Repo.Migrations.CreateTblUserLogs do
  use Ecto.Migration

  def change do
    create table(:tbl_user_logs) do
      add :activity, :string
      add :user_id, references(:tbl_user, column: :id, on_delete: :delete_all)

      timestamps()
    end
  end
end
