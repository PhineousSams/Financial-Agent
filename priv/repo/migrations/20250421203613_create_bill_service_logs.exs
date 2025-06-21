defmodule ServiceManager.Repo.Migrations.CreateBillServiceLogs do
  use Ecto.Migration

  def change do
    create table(:tbl_service_logs) do 
      add :request_type, :string, null: false  # "details" or "transaction"
      add :request_id, :string, null: false
      add :request_url, :string, null: false
      add :request_method, :string, null: false
      add :request_headers, :map
      add :request_body, :map
      add :response_code, :integer
      add :response_body, :map
      add :duration_ms, :integer
      add :status, :string, null: false  # "success", "error", "pending"
      add :error_message, :text
      add :metadata, :map
      add :service_type, :string
      add :service_id, :string

      timestamps(type: :utc_datetime)
    end

    create unique_index(:tbl_service_logs, [:request_id])
    create index(:tbl_service_logs, [:status])
    create index(:tbl_service_logs, [:request_type])
    create index(:tbl_service_logs, [:service_type])
    create index(:tbl_service_logs, [:service_id])
  end
end
