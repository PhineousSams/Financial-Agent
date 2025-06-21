defmodule FinincialTool.Repo.Migrations.AlterTblUserLogsAddFields do
  use Ecto.Migration

  def up do
    alter table(:tbl_user_logs) do
      add :pre_data, :map
      add :post_data, :map
      add :action, :string
    end
  end

  def down do
    alter table(:tbl_user_logs) do
      remove(:pre_data)
      remove(:post_data)
      remove(:action)
    end
  end
end
