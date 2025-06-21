defmodule FinincialTool.Repo.Migrations.CreateTblUser do
  use Ecto.Migration

  def change do
    create table(:tbl_user) do
      add :first_name, :string, size: 30
      add :last_name, :string, size: 30
      add :other_name, :string, size: 30
      add :title, :string, size: 30
      add :username, :string, size: 30
      add :email, :string, null: false, size: 80
      add :password, :string, size: 255
      add :hashed_password, :string, null: false
      add :auto_pwd, :boolean
      add :sex, :string, size: 10
      add :dob, :date
      add :id_no, :string, size: 30
      add :phone, :string, size: 20
      add :address, :string, size: 100
      add :status, :string
      add :blocked, :boolean
      add :user_type, :string
      add :failed_attempts, :integer, default: 0
      add :pwd_reuse, :integer
      add :area, :string, size: 30
      add :plot_number, :string, size: 30
      add :street_name, :string, size: 30
      add :resedential_years, :integer
      add :accomodation_status, :string, size: 30
      add :approved_at, :naive_datetime
      add :confirmed_at, :naive_datetime
      add :last_login, :naive_datetime
      add :user_class, :string
      add :remark, :string
      add :maker_id, references(:tbl_user, column: :id, on_delete: :nothing)
      add :updated_by, references(:tbl_user, column: :id, on_delete: :nothing)
      add :role_id, references(:tbl_user_role, column: :id, on_delete: :nothing)

      timestamps()
    end

    create index(:tbl_user, [:username])
    create unique_index(:tbl_user, [:username, :email, :phone])
  end
end
