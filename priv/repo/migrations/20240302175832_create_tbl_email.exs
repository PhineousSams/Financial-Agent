defmodule FinincialAgent.Repo.Migrations.CreateTblEmail do
  use Ecto.Migration

  def change do
    create table(:tbl_email) do
      add :subject, :string
      add :sender_email, :string
      add :sender_name, :string
      add :mail_body, :string
      add :recipient_email, :string
      add :status, :string
      add :attempts, :string

      timestamps()
    end
  end
end
