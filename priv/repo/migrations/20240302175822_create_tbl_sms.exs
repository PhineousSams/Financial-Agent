defmodule FinancialAgent.Repo.Migrations.CreateTblSms do
  use Ecto.Migration

  def change do
    create table(:tbl_sms) do
      add :type, :string
      add :mobile, :string
      add :sms, :string
      add :status, :string
      add :msg_count, :integer
      add :date_sent, :string

      timestamps()
    end
  end
end
