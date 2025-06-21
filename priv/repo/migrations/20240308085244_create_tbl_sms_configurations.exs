defmodule Loans.Repo.Migrations.CreateTblSmsConfigurations do
  use Ecto.Migration

  def change do
    create table(:tbl_sms_configuration) do
      add :username, :string
      add :password, :string
      add :host, :string
      add :sender, :string
      add :max_attempts, :string
      add :status, :string
      timestamps()
    end
  end
end
