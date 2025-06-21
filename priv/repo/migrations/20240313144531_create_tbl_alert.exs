defmodule LoansSystem.Repo.Migrations.CreateTblAlert do
  use Ecto.Migration

  def change do
    create table(:tbl_alert) do
      add :alert_type, :string, size: 50
      add :description, :string, size: 150
      add :message, :string, size: 150
      add :status, :string, size: 30
      add :created_by_id, :integer
      add :approved_by_id, :integer

      timestamps()
    end
  end
end
