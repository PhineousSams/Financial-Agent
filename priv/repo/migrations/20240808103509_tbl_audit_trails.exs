defmodule FinincialTool.Repo.Migrations.TblAuditTrails do
  use Ecto.Migration

  def change do
    create table(:tbl_audit_logs) do
      add :action, :string
      add :description, :string
      add :resource_type, :string
      add :resource_id, :integer
      add :pre_data, :map
      add :post_data, :map
      add :metadata, :map
      add :user_id, references(:tbl_user, on_delete: :nothing)

      timestamps(inserted_at: :created_at, type: :utc_datetime)
    end
  end
end
