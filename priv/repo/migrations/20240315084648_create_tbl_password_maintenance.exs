defmodule FinincialAgent.Repo.Migrations.CreateTblPasswordMaintenance do
  use Ecto.Migration

  def change do
    create table(:tbl_password_maintenance) do
      add :name, :string
      add :min_characters, :integer
      add :max_characters, :integer
      add :repetitive_characters, :integer
      add :sequential_numeric, :integer
      add :reuse, :integer
      add :restriction, :boolean
      add :max_attempts, :integer
      add :force_change, :integer
      add :min_special, :integer
      add :min_numeric, :integer
      add :min_lower_case, :integer
      add :min_upper_case, :integer
      add :maker_id, references(:tbl_user, on_delete: :nothing)
      add :updated_by, references(:tbl_user, on_delete: :nothing)
      timestamps()
    end
  end
end
