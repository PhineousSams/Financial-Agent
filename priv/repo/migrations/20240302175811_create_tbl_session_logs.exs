defmodule FinancialAgent.Repo.Migrations.CreateTblSessionLogs do
  use Ecto.Migration

  def change do
    create table(:tbl_session_logs) do
      add :session_id, :string, size: 400, null: false
      add :portal, :string, size: 50, null: false
      add :description, :string, size: 300, null: false
      add :device_uuid, :string, null: true
      add :ip_address, :string, size: 50, null: true
      add :full_browser_name, :string, size: 200, null: true
      add :browser_details, :string, size: 200, null: true
      add :system_platform_name, :string, size: 300, null: true
      add :device_type, :string, size: 150, null: true
      add :known_browser, :boolean, null: true
      add :status, :boolean, default: true
      add :user_id, references(:tbl_user, on_delete: :delete_all)

      timestamps()
    end
  end
end
