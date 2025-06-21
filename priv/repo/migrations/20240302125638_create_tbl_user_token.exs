defmodule FinincialAgent.Repo.Migrations.CreateTblUserToken do
  use Ecto.Migration

  def change do
    create table(:tbl_user_tokens) do
      add :user_id, references(:tbl_user, on_delete: :delete_all), null: false
      add :token, :binary, null: false
      add :context, :string, null: false
      add :sent_to, :string
      add :login_timestamp, :naive_datetime

      timestamps(updated_at: false)
    end

    create index(:tbl_user_tokens, [:user_id])
    create unique_index(:tbl_user_tokens, [:context, :token])
  end
end
