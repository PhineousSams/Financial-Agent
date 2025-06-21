defmodule FinancialAgent.Repo.Migrations.CreateApiIntegrators do
  use Ecto.Migration

  def change do
    create table(:tbl_api_integrators) do
      add :name, :string, null: false
      add :integrator_id, :uuid, null: false
      add :callback_url, :string
      add :endpoint, :string, null: false
      add :auth_token, :string
      add :expires_at, :utc_datetime
      add :revoked_at, :utc_datetime
      add :status, :string
      add :password_hash, :string
      add :attempt_count, :integer
      add :contact_email, :string, null: false
      add :ip_address, :string, comment: "IP address for whitelisting"
      add :port, :integer, comment: "Port number for whitelisting"
      add :maker_id, references(:tbl_user, on_delete: :nothing), null: false
      add :checker_id, references(:tbl_user, on_delete: :nothing), null: false

      timestamps()
    end

    create unique_index(:tbl_api_integrators, [:integrator_id])
    create unique_index(:tbl_api_integrators, [:name])
  end
end
