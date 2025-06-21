defmodule FinincialAgent.Repo.Migrations.CreateTblConfigSettings do
  use Ecto.Migration

  def change do
    create table(:tbl_config_settings) do
      add :name, :string, size: 50, null: false
      add :value, :string, size: 50, null: true
      add :value_type, :string, size: 50, null: true
      add :description, :string, size: 150, null: true
      add :deleted_at, :naive_datetime, null: true
      add :updated_by, :string, size: 50, null: true

      timestamps()
    end
  end
end
