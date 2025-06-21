defmodule FinincialTool.Repo.Migrations.CreateApiLogs do
  use Ecto.Migration

  def change do
    create table(:tbl_api_logs) do
      add :ref_id, :string
      add :api_key, :string
      add :endpoint, :string, null: false
      add :request_method, :string, null: false
      add :request_path, :string, null: false
      add :request_params, :map
      add :response_status, :integer
      add :response_body, :map
      add :processing_time_ms, :integer
      add :ip_address, :string
      add :user_agent, :string
      add :error_details, :map
      add :service_type, :string
      add :service_id, :string

      timestamps(type: :utc_datetime)
    end
    create index(:tbl_api_logs, [:api_key])
    create index(:tbl_api_logs, [:service_id])
    create index(:tbl_api_logs, [:endpoint])
    create index(:tbl_api_logs, [:inserted_at])
  end
end
