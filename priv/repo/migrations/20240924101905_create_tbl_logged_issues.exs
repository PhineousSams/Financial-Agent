defmodule FinancialAgent.Repo.Migrations.CreateTblLoggedIssues do
  use Ecto.Migration

  def change do
    create table(:tbl_logged_issues) do
      add :alt_email, :string
      add :client_name, :string
      add :date_reported, :string
      add :error_type, :string
      add :platiform_name, :string
      add :prim_email, :string
      add :report, :string
      add :resolver_resp, :string
      add :date_resolved, :naive_datetime
      add :issue_status, :string
      add :screen_shot, :string
      add :reporter_id, :integer
      add :resolver_id, :integer
      add :assigned_to, :string
      add :tracking_number, :string


      timestamps()
    end
  end
end
