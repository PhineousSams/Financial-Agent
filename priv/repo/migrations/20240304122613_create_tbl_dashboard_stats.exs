defmodule FinincialAgent.Repo.Migrations.CreateTblDashboardStats do
  use Ecto.Migration

  def change do
    create table(:tbl_dashboard_stats) do
      add :name, :string
      add :value, :string, size: 1500

      timestamps()
    end
  end
end
