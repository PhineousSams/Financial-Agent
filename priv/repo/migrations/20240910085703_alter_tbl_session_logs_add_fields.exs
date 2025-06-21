defmodule FinancialAgent.Repo.Migrations.AlterTblSessionLogsAddFields do
  use Ecto.Migration

  def up do
    alter table(:tbl_session_logs) do
      add :pre_data, :map
      add :post_data, :map
    end
  end

  def down do
    alter table(:tbl_session_logs) do
      remove(:pre_data)
      remove(:post_data)
    end
  end
end
